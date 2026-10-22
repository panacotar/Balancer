import * as esbuild from 'esbuild';
import { rm } from 'node:fs/promises';

if (process.env.RAILS_ENV === 'production') await rm('app/assets/builds/application.js.map', { force: true });

const options = {
  entryPoints: ['app/javascript/application.js'],
  outdir: 'app/assets/builds',
  bundle: true,
  sourcemap: process.env.RAILS_ENV !== 'production',
  minify: process.env.RAILS_ENV === 'production',
  target: ['es2020'],
  inject: ['app/javascript/jquery.js'],
  logLevel: 'info'
};

if (process.argv.includes('--watch')) {
  const context = await esbuild.context(options);
  await context.watch();
} else {
  await esbuild.build(options);
}
