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
- esbuild and Dart Sass
- flatpickr, slick-carousel, and Popper.js

## Setup

Install Ruby 3.4.11, Node 24, and PostgreSQL, then run:

```
bin/setup
```

That installs gems and npm packages, builds the assets, and prepares the database. On a new database it also loads the sample data.

To seed an existing database, run:

```
bin/rails db:seed
```

To drop the database and seed it again, run `bin/rails db:reset`.

Uploaded photos, including the ones created by the seed, are saved in the `storage/` directory at the project root. That directory is not committed.

## Running

```
bin/dev
```

The app is at http://localhost:3000. `bin/dev` starts Rails and rebuilds JavaScript and CSS as you edit.

## Environment

Copy `.env.example` to `.env` and fill in the values. Development and test read that file. Stripe setup, including `STRIPE_WEBHOOK_SECRET`, is in [doc/stripe.md](doc/stripe.md).

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

