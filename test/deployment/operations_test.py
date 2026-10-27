import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

# This fake exercises shell control flow under provider failures, without
# needing Docker or touching the user's real Compose projects.
DOCKER = r'''#!/usr/bin/env python3
import io,json,os,sys,tarfile
from pathlib import Path
state=Path(os.environ['FAKE_STATE'])
args=sys.argv[1:]
with (state/'calls').open('a') as log: log.write(json.dumps(args)+'\n')
if args[:2]==['image','inspect']:
 print('arm64'); sys.exit()
if args[0]=='inspect':
 print('balancer:old'); sys.exit()
if args[:2]==['network','inspect']: sys.exit()
assert args[0]=='compose', args
args=args[1:]
while args and (args[0].startswith('--') or args[0]=='-f'):
 args=args[2:]
if args[0]=='config':
 print(json.dumps({'services':{'web':{'image':'balancer:new','environment':{'DOMAIN':'example.test'}}},'networks':{'edge':{'name':'test-edge'}}})); sys.exit()
if args[0]=='ps':
 if (state/'running').exists(): print('web')
 sys.exit()
if args[:2]==['stop','web']:
 (state/'running').unlink(missing_ok=True); sys.exit()
if args[0]=='up':
 if 'web' in args:
  (state/'running').touch()
  (state/'running-image').write_text(os.environ.get('APP_IMAGE','balancer:new'))
 sys.exit()
if 'psql' in args:
 print(os.environ.get('TABLE_COUNT','0')); sys.exit()
if 'pg_dump' in args:
 if os.environ.get('FAIL_DUMP'): sys.exit(1)
 sys.stdout.buffer.write(b'test-database'); sys.exit()
if args[0]=='run':
 if 'db:migrate' in args: sys.exit(1 if os.environ.get('FAIL_MIGRATE') else 0)
 if 'tar' in args:
  with tarfile.open(fileobj=sys.stdout.buffer,mode='w|gz') as archive:
   data=b'photo-bytes'; member=tarfile.TarInfo('./photo'); member.size=len(data)
   archive.addfile(member,io.BytesIO(data))
 sys.exit()
sys.exit()
'''


class OperationsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / 'scripts', self.root / 'scripts')
        shutil.copy(ROOT / 'compose.production.yaml', self.root)
        shutil.copy(ROOT / '.env.production.example', self.root)
        self.state = self.root / 'state'
        self.state.mkdir()
        (self.state / 'running').touch()
        (self.root / 'bin').mkdir()
        docker = self.root / 'bin/docker'
        docker.write_text(DOCKER)
        docker.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{self.root}/bin:{os.environ["PATH"]}', FAKE_STATE=str(self.state))
        self.run_script('setup-production.sh')

    def run_script(self, name, *args, **env):
        return subprocess.run(['bash', str(self.root / 'scripts' / name), *args],
                              env=dict(self.env, **env), capture_output=True, text=True)

    def test_setup_preserves_existing_secrets(self):
        secret = self.root / 'deploy/secrets/db_password'
        original = secret.read_bytes()
        result = self.run_script('setup-production.sh')
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(original, secret.read_bytes())
        self.assertEqual(0o700, secret.parent.stat().st_mode & 0o777)

    def test_backup_failure_restarts_previously_running_app_and_releases_lock(self):
        result = self.run_script('backup-production.sh', FAIL_DUMP='1')
        self.assertNotEqual(0, result.returncode)
        self.assertTrue((self.state / 'running').exists())
        self.assertEqual('balancer:old', (self.state / 'running-image').read_text())
        self.assertFalse((self.root / '.production-operation.lock').exists())
        self.assertEqual([], list((self.root / 'backups').glob('*.tar.gz')))

    def test_backup_of_stopped_app_does_not_start_it(self):
        (self.state / 'running').unlink()
        result = self.run_script('backup-production.sh')
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertFalse((self.state / 'running').exists())
        archive = next((self.root / 'backups').glob('*.tar.gz'))
        stage = self.root / 'verify'
        stage.mkdir()
        checked = subprocess.run(['python3', str(ROOT / 'scripts/deploy/validate-backup.py'),
                                  str(archive), str(stage)], capture_output=True, text=True)
        self.assertEqual(0, checked.returncode, checked.stderr)
        self.assertEqual(b'test-database', (stage / 'database.dump').read_bytes())

    def test_migration_failure_preserves_backup_and_leaves_app_stopped(self):
        (self.root / '.release').write_text('balancer:old\n')
        result = self.run_script('deploy-production.sh', 'update', FAIL_MIGRATE='1')
        self.assertNotEqual(0, result.returncode)
        self.assertFalse((self.state / 'running').exists())
        self.assertEqual('balancer:old\n', (self.root / '.release').read_text())
        self.assertEqual('balancer:old\n', (self.root / '.previous-release').read_text())
        self.assertEqual(1, len(list((self.root / 'backups').glob('*.tar.gz'))))

    def test_init_refuses_populated_database_without_stopping_web(self):
        result = self.run_script('deploy-production.sh', 'init', TABLE_COUNT='5')
        self.assertNotEqual(0, result.returncode)
        self.assertIn('empty database', result.stderr)
        self.assertTrue((self.state / 'running').exists())
        self.assertNotIn('db:migrate', (self.state / 'calls').read_text())

    def test_existing_lock_prevents_any_docker_operation(self):
        (self.root / '.production-operation.lock').mkdir()
        result = self.run_script('backup-production.sh')
        self.assertNotEqual(0, result.returncode)
        self.assertTrue((self.root / '.production-operation.lock').exists())
        self.assertFalse((self.state / 'calls').exists())


class BackupValidationTest(unittest.TestCase):
    def test_rejects_path_traversal_and_links_before_extraction(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, kind in [('../escaped', tarfile.REGTYPE), ('FORMAT', tarfile.SYMTYPE)]:
                with self.subTest(name=name):
                    archive = root / 'bad.tar.gz'
                    with tarfile.open(archive, 'w:gz') as bundle:
                        member = tarfile.TarInfo(name)
                        member.type = kind
                        member.linkname = '/etc/passwd'
                        bundle.addfile(member, io.BytesIO())
                    result = subprocess.run(['python3', str(ROOT / 'scripts/deploy/validate-backup.py'),
                                             str(archive), str(root)], capture_output=True)
                    self.assertNotEqual(0, result.returncode)
                    self.assertFalse((root.parent / 'escaped').exists())

    def test_rejects_corrupted_recovery_set(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            contents = {'FORMAT': b'balancer-backup-v1\n', 'image.txt': b'balancer:old',
                        'database.dump': b'corrupt', 'uploads.tar.gz': b'corrupt',
                        'SHA256SUMS': b'bad  database.dump\nbad  uploads.tar.gz\n'}
            archive = root / 'bad.tar.gz'
            with tarfile.open(archive, 'w:gz') as bundle:
                for name, data in contents.items():
                    member = tarfile.TarInfo(name)
                    member.size = len(data)
                    bundle.addfile(member, io.BytesIO(data))
            result = subprocess.run(['python3', str(ROOT / 'scripts/deploy/validate-backup.py'),
                                     str(archive), str(root)], capture_output=True)
            self.assertNotEqual(0, result.returncode)
            self.assertIn(b'checksum mismatch', result.stderr)


if __name__ == '__main__':
    unittest.main()
