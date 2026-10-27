## Balancer 

For current setup, VPS deployment, testing, and upgrade details, see the [modernization guide](docs/modernization.md).

A social impact investing platform supporting entrepreneurs from underrepresented groups.

Entrepreneurs can add their projects and create campaigns for raising funding.

Investors are able to browse through campaigns and make a pledge.


## Contributors

Many thanks to all the [people](https://github.com/panacotar/Balancer/graphs/contributors) that contributed to this project. 

-----------------------------


### Built using:

- Ruby 3.4 and Rails 8.1
- PostgreSQL 15+
- Bootstrap 4, jQuery, Flatpickr, Slick, and amCharts
- Stripe (test mode), Active Storage, and optional Cloudinary
- esbuild, Dart Sass, and Sprockets

## Setup

- Select the Ruby/Node versions in `.ruby-version` and `.node-version`, and start PostgreSQL.
- Copy `.env.example` to `.env`, then run `bin/setup`.
- Run `bin/rails server` and open [localhost:3000](http://localhost:3000).

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
