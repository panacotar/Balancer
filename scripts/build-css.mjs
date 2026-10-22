import * as sass from 'sass';
import postcss from 'postcss';
import autoprefixer from 'autoprefixer';
import { mkdir, writeFile, cp } from 'node:fs/promises';
import { watch } from 'node:fs';

async function build() {
  const result = sass.compile('app/assets/stylesheets/application.sass.scss', {
    loadPaths: ['node_modules', 'app/assets/stylesheets'],
    style: process.env.RAILS_ENV === 'production' ? 'compressed' : 'expanded',
    // Bootstrap 4 and our existing SCSS use deprecated Sass imports and color helpers.
    // The Bootstrap 5 follow-up will remove these; errors are never suppressed.
    silenceDeprecations: ['import', 'global-builtin', 'color-functions', 'legacy-js-api', 'if-function']
  });
  const output = await postcss([autoprefixer]).process(result.css, { from: undefined, map: false });
  await mkdir('app/assets/builds', { recursive: true });
  await writeFile('app/assets/builds/application.css', output.css);
  await cp('node_modules/@fortawesome/fontawesome-free/webfonts', 'app/assets/builds/webfonts', { recursive: true });
  await cp('node_modules/slick-carousel/slick/fonts', 'app/assets/builds/fonts', { recursive: true });
  await cp('node_modules/slick-carousel/slick/ajax-loader.gif', 'app/assets/builds/ajax-loader.gif');
  console.log('Built application.css and fonts');
}

await build();
if (process.argv.includes('--watch')) {
  let pending;
  watch('app/assets/stylesheets', { recursive: true }, () => {
    clearTimeout(pending);
    pending = setTimeout(() => build().catch(error => { console.error(error); process.exitCode = 1; }), 100);
  });
}
