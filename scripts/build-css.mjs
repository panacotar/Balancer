import * as sass from 'sass';
import postcss from 'postcss';
import autoprefixer from 'autoprefixer';
import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { watch } from 'node:fs';

const style = process.env.RAILS_ENV === 'production' ? 'compressed' : 'expanded';
// Bootstrap 4 still uses the Sass syntax these warnings describe.
const silenceDeprecations = ['import', 'global-builtin', 'color-functions', 'legacy-js-api', 'mixed-decls', 'abs-percent'];

async function compile(entry, outfile, prefix = '') {
  const result = sass.compile(entry, {
    loadPaths: ['node_modules', 'app/assets/stylesheets', 'app/javascript/styles'],
    style,
    silenceDeprecations
  });
  const output = await postcss([autoprefixer]).process(result.css, { from: undefined });
  await writeFile(outfile, prefix + output.css);
}

async function build() {
  await mkdir('app/assets/builds', { recursive: true });
  const aos = await readFile('node_modules/aos/dist/aos.css', 'utf8');
  await compile('app/assets/stylesheets/application.sass.scss', 'app/assets/builds/application.css');
  await compile('app/javascript/styles/pack.scss', 'app/assets/builds/pack.css', aos);
  await cp('node_modules/@fortawesome/fontawesome-free/webfonts', 'public/webfonts', { recursive: true });
  await cp('node_modules/slick-carousel/slick/fonts', 'public/slick/fonts', { recursive: true });
  await cp('node_modules/slick-carousel/slick/ajax-loader.gif', 'public/slick/ajax-loader.gif');
  await mkdir('public/images', { recursive: true });
  await cp('app/assets/images/bg_buswoman.jpg', 'public/images/bg_buswoman.jpg');
  await cp('app/assets/images/photo-1.png', 'public/images/photo-1.png');
  console.log('Built application.css, pack.css, and fonts');
}

await build();

if (process.argv.includes('--watch')) {
  let pending;
  const rebuild = () => {
    clearTimeout(pending);
    pending = setTimeout(() => {
      build().catch((error) => {
        console.error(error);
      });
    }, 100);
  };
  watch('app/assets/stylesheets', { recursive: true }, rebuild);
  watch('app/javascript/styles', { recursive: true }, rebuild);
}
