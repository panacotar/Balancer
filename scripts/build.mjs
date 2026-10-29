import * as esbuild from 'esbuild';
import { rm } from 'node:fs/promises';

if (process.env.RAILS_ENV === 'production') {
  await rm('app/assets/builds/application.js.map', { force: true });
}

const options = {
  entryPoints: ['app/javascript/packs/application.js'],
  outfile: 'app/assets/builds/application.js',
  bundle: true,
  sourcemap: process.env.RAILS_ENV !== 'production',
  minify: process.env.RAILS_ENV === 'production',
  target: ['es2020'],
  inject: ['app/javascript/jquery.js'],
  logLevel: 'info',
  define: { global: 'window' }
};

if (process.argv.includes('--watch')) {
  const context = await esbuild.context(options);
  await context.watch();
} else {
  await esbuild.build(options);
}
