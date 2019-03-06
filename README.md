# Production Docker environment for CONSUL
This is an experimental repository for testing ways to deploy a production instance of CONSUL using Docker. The initial use case is to deploy a Production-ready demo instance as a proof-of-concept.

For purposes of disambiguation "CONSUL" here refers to [the citizen participation software](https://github.com/consul/consul) distributed by the [CONSUL Project](http://consulproject.org/) and not the [service discovery software](https://www.consul.io/) from [Hashicorp](https://www.hashicorp.com/).

## Service Architecture
In production, we assume that the stack this generates will not be directly exposed to the internet but will be behind a separately configured reverse proxy to provide at least HTTPS termination and any cacheing, additional access controls or other security measures.

We are using Docker Swarm in Production and Docker Compose for test/dev, so the scripts operate on this basis and use `docker stack` or `docker compose` commands.

We assume that the production stack will not require a database container and that the database will be provided by a more appropriate service (we manage our own database cluster, but you may use something like Cloud SQL or RDS).

As a result, the `docker-compose.yml` file contains the following services:

 - memcache
 - consul app server (exposing a port)
 - consul jobs server (no port exposed, for polling the `delayed_job` queue)

There is an additional `docker-compose-database.yml` that includes a database service. This is included when running with Compose.

## Using this repository
This repository uses a variation on the [Scripts to rule them all](https://github.com/github/scripts-to-rule-them-all) pattern.

### Configuration
Most configuration can and should be done via environment variables. There are defaults set in the compose files, often based on mySociety's requirements so be sure to review these and decide what need to be changed for your needs.

#### Repository Actions
These variables affect the behaviour of the various scripts:

| Variable | Description |
| --------|-------------|
| `CONTEXT` | Set to `build` when solely building images. `all` will be used when running services. |
| `UPDATE` | When starting the service via `script/server`, whether to run a database migration. |
| `PUSH_IMAGES` | When building Docker images, whether to push them to Docker Hub. |
|`BUILD_TAG`| This is set to the latest git commit hash, but could be overridden.|

#### Application Configuration
These are all passed through to the containers running the service and are used to configure the application.

Pay particular attention to the `POSTGRES_*` variables for configuring the database connections and the `CONFIG_SMTP_*` variables for managing email.

| Variable | Description |
| --------|-------------|
| `TAG` | Tag used for the Consul containers, defaults to `latest` |
| `PORT` | The host port exposing the application's endpoint |
| `MEMCACHE_SERVERS`| As used by the `dalli` gem |
| `RAILS_ENV` | The Rails environment |
| `POSTGRES_HOST` | Postgres server hostname | 
| `POSTGRES_PORT` | Postgres server port | 
| `POSTGRES_DB` | Database name to connect to | 
| `POSTGRES_USER` | Postgres user to make connection as | 
| `POSTGRES_PASSWORD` | Password for the Postgres user |
|`SERVER_NAME` | Name of the server, e.g. consul.example.com |
| `RAILS_SERVE_STATIC_FILES` | Whether or not to have Rails serve static files |
| `NEW_RELIC_AGENT_ENABLED` | Whether to enable New Relic agent |
| `CONFIG_FORCE_SSL` | Whether to enforce SSL connections |
| `CONFIG_SMTP_ENABLE` | Whether to set up Active Mailer |
| `CONFIG_SMTP_ADDRESS` | Address of your SMTP server |
| `CONFIG_SMTP_PORT` | Port to use for SMTP |
| `CONFIG_SMTP_DOMAIN` | What to use for the `EHLO`/`HELO` command |
| `CONFIG_SMTP_USERNAME` | Username to use for SMTP Auth |
| `CONFIG_SMTP_PASSWORD` | Password to use for SMTP Auth |

### Scripts
Here follows a brief discussion of each script.

#### Bootstrap
`script/bootstrap` will ensure that any required Docker images are pulled.

#### Setup
`script/setup` can be used on a fresh clone to configure the repository for the first time, or if you want to reset your environment to its original state. By default, it will:

* reset the CONSUL submodule and discard any local changes.
* remove all running containers, networks and volumes.
* initialise the database.
* optionally load test data into the database.

As there are two distinct sets of tasks that this attempts to address, building images and deploying a service based upon them, `script/setup` can be configured appropriately using the `CONTEXT` environment variable.

If you want to configure the repository simply for image builds (eg as part of a build pipeline or other automation, or you wish to reset for a clean build without removing your existing Docker volumes and containers), run `CONTEXT=build script/setup`.

If you want to seed the database with the test data, run `SEED_DB=true script/setup`. This will be ignored if you have also set `CONTEXT=build`.

Note that the seed data only makes sense for a demo site.

#### Update
`script/update` can be run on an existing working copy following a pull. By default, it will:

* ensure the CONSUL submodule is checked out at the appropriate revision; local changes will be retained.
* stop any running containers; volumes will be retained.
* Start a database container and run a migration.
* Stop and remove the temporary containers, leaving the stack down.

If you run `CONTEXT=build script/setup`, it will call `script/setup` (preserving the environment), then stop. If you want to run a build, it makes no sense to retain local changes - this isn't intended to be used for CONSUL development.

#### Build
`script/build` attempts to build a Docker image tagged with the current commit hash as follows:

* Exports `CONTEXT=build`.
* Runs `script/setup` to ensure the build is clean.
* Checks whether an image with the tag already exists.
* Builds the image, if necessary.
* Additionally tags the image as `latest`.
* Optionally (if `PUSH_IMAGE=true`) pushes the resulting image and tags to Docker Hub.

#### Test
`script/test` currently checks and dumps a processed version of `docker-compose.yml`, this is useful if you want to confirm what values will be interpolated for the various embedded variables.

#### Run
`script/server` will start the service stack in the appropriate manner for your platform.

`script/server --stop` will stop the service.

Optionally set `UPDATE=true` to call `script/update` to perform database migrations when starting the service.

