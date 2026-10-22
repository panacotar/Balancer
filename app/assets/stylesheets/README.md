# Stylesheets

`application.sass.scss` is the SCSS entrypoint. It imports the existing variables,
Bootstrap 4, Font Awesome, Flatpickr, AOS, Slick, and the app's components/pages.

Use `npm ci` to install packages and `npm run build:css` to compile SCSS with Dart
Sass and Autoprefixer. `npm run build:css -- --watch` watches local changes;
`bin/dev` runs the watcher alongside Rails and JavaScript rebuilding.

Compiled CSS, fonts, and carousel images live in the ignored `app/assets/builds/`
directory. Sprockets fingerprints and serves them. Use normal `url(...)` references
for assets, not the old SassC `asset-url(...)` helper.

Bootstrap 5 and broader frontend replacements are separate follow-ups. See the
root README and `docs/modernization.md` for runtime requirements and maintenance debt.
