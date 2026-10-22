## Balancer 

For current setup, testing, and upgrade details, see the [modernization guide](docs/modernization.md).

A social impact investing platform supporting entrepreneurs from underrepresented groups.

Entrepreneurs can add their projects and create campaigns for raising funding.

Investors are able to browse through campaigns and make a pledge.


[Balancer in production](https://balancer-app.fly.dev "CTRL/CMD + click to open in a new tab")


## Contributors

Many thanks to all the [people](https://github.com/panacotar/Balancer/graphs/contributors) that contributed to this project. 

-----------------------------


### Built using:

- Ruby 3.4 and Rails 8.1
- PostgreSQL 15+
- Bootstrap 4, jQuery, Flatpickr, Slick, and amCharts
- Stripe (test mode) and Cloudinary
- esbuild, Dart Sass, and Sprockets

## Setup

- Select the Ruby/Node versions in `.ruby-version` and `.node-version`, and start PostgreSQL.
- Copy `.env.example` to `.env`, then run `bin/setup`.
- Run `bin/rails server` and open [localhost:3000](http://localhost:3000).

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.


<!--  
Notes on Fly.io:
- The free plan allows only 3 machines tops. Here is how the default configuration looked for Balancer on fly.io
- - There are 3 apps (balancer, db, builder - used for deploys)
- - Each of them is on a different machine, balancer used 2 machines by default
- - In total, 4 machines (2x balancer, 1x db, 1x builder), which is bigger than the minimum for this free tier
- - I modified the number of machines for the main app (balancer) to 1
- - fly scale count 1 (CLI to modify the # of machines)

- An alternative to this would be to do some steps after deployment (maybe a bash script):
- - Remove the builder app with its machine
- - Clone one machine of the balancer app (so now you can have two machines to power it) 

To remove an app
fly apps destroy <APPNAME>

To remove a machine
fly m remove <MACHINE_ID>

To clone a machine
fly m clone <MACHINE_ID>

For the CLI:
- Run a rails command on the app's console
fly ssh console --pty -C '/rails/bin/rails console'
-->
