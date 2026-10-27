#!/usr/bin/env python3
"""Validate/extract only our five fixed backup members into a new staging directory."""
import hashlib
from pathlib import Path, PurePosixPath
import sys
import tarfile

archive, destination = sys.argv[1:]
root = Path(destination)
names = {'FORMAT', 'image.txt', 'SHA256SUMS', 'database.dump', 'uploads.tar.gz'}
with tarfile.open(archive, 'r:gz') as bundle:
    members = bundle.getmembers()
    if len(members) != len(names) or {m.name for m in members} != names or not all(m.isfile() for m in members):
        raise SystemExit('Not a Balancer backup: unexpected archive members')
    for member in members:
        with bundle.extractfile(member) as source, (root / member.name).open('wb') as target:
            while chunk := source.read(1024 * 1024):
                target.write(chunk)
if (root / 'FORMAT').read_text() != 'balancer-backup-v1\n':
    raise SystemExit('Unsupported backup format')
checksums = {}
for line in (root / 'SHA256SUMS').read_text().splitlines():
    digest, name = line.split()
    checksums[name] = digest
if set(checksums) != {'database.dump', 'uploads.tar.gz'}:
    raise SystemExit('Invalid checksum manifest')
for name, expected in checksums.items():
    digest = hashlib.sha256()
    with (root / name).open('rb') as source:
        while chunk := source.read(1024 * 1024):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        raise SystemExit('Backup checksum mismatch')
with tarfile.open(root / 'uploads.tar.gz', 'r:gz') as uploads:
    for member in uploads:
        path = PurePosixPath(member.name)
        if path.is_absolute() or '..' in path.parts or not (member.isfile() or member.isdir()):
            raise SystemExit('Unsafe upload archive member')
