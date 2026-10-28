## Balancer 

A social impact investing platform supporting entrepreneurs from underrepresented groups.

Entrepreneurs can add their projects and create campaigns for raising funding.

Investors are able to browse through campaigns and make a pledge.


## Contributors

Many thanks to all the [people](https://github.com/panacotar/Balancer/graphs/contributors) that contributed to this project. 

-----------------------------


### Built using:
- Ruby 3.4 and Rails 8.1
- PostgreSQL
- Bootstrap 4
- Stripe
- Cloudinary
- esbuild and Dart Sass
- flatpickr, slick-carousel, and Popper.js

## Setup

Install Ruby 3.4.11, Node 24, and PostgreSQL, then run:

```
bin/setup
```

That installs gems and npm packages, builds the assets, and prepares the database.

## Running

```
bin/dev
```

The app is at http://localhost:3000. `bin/dev` starts Rails and rebuilds JavaScript and CSS as you edit.

## Environment

Create a `.env` file in the project root. These are read in development and test:

- `CLOUDINARY_URL` (Cloudinary console > Dashboard). Required to upload photos and to seed projects.
- `STRIPE_PUBLISHABLE_KEY` and `STRIPE_SECRET_KEY`. Use Stripe test keys.
- `STRIPE_WEBHOOK_SECRET`. Required for `POST /stripe/webhook`. Checkout still completes from the return URL without it.

In production, set `DOMAIN` to the public hostname. `SENTRY_DSN` is optional.

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

