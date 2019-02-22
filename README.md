# Production Docker environment for CONSUL

This is an experimental repository for testing ways to deploy a production instance of CONSUL using Docker. The initial use case is to deploy a Production-ready demo instance as a proof-of-concept.

For purposes of disambiguation "CONSUL" here refers to [the citizen participation software](https://github.com/consul/consul) distributed by the [CONSUL Project](http://consulproject.org/) and not the [service discovery software](https://www.consul.io/) from [Hashicorp](https://www.hashicorp.com/).

## Using this repository

This repository uses a variation on the [Scripts to rule them all](https://github.com/github/scripts-to-rule-them-all) pattern.

### Bootstrap

`script/bootstrap` will ensure that any required Docker images are pulled.

### Setup

`script/setup` can be used on a fresh clone to configure the repository for the first time, or if you want to reset your environment to its original state. By default, it will:

* reset the CONSUL submodule and discard any local changes.
* remove all running containers, networks and volumes.
* initialise the database.
* optionally load test data into the database.

As there are two distinct sets of tasks that this attempts to address, building images and deploying a service based upon them, `script/setup` can be configured appropriately using the `CONTEXT` environment variable.

If you want to configure the repository simply for image builds (eg as part of a build pipeline or other automation, or you wish to reset for a clean build without removing your existing Docker volumes and containers), run `CONTEXT=build script/setup`.

If you want to seed the database with the test data, run `SEED_DB=true script/setup`. This will be ignored if you have also set `CONTEXT=build`.

Note that the seed data only makes sense for a demo site.

### Update

`script/update` can be run on an existing working copy following a pull. By default, it will:

* ensure the CONSUL submodule is checked out at the appropriate revision; local changes will be retained.
* stop any running containers; volumes will be retained.
* Start a database container and run a migration.
* Stop and remove the temporary containers, leaving the stack down.

If you run `CONTEXT=build script/setup`, it will call `script/setup` (preserving the environment), then stop. If you want to run a build, it makes no sense to retain local changes - this isn't intended to be used for CONSUL development.

### Build

`script/build` attempts to build a Docker image tagged with the current commit hash as follows:

* Exports `CONTEXT=build`.
* Runs `script/setup` to ensure the build is clean.
* Checks whether an image with the tag already exists.
* Builds the image, if necessary.
* Additionally tags the image as `latest`.
* Optionally (if `PUSH_IMAGE=true`) pushes the resulting image and tags to Docker Hub.

### Test

`script/test` currently checks and dumps a processed version of `docker-compose.yml`, this is useful if you want to confirm what values will be interpolated for the various embedded variables.

### Run

`script/server` will start the service stack in the appropriate manner for your platform.

`script/server --stop` will stop the service.

Optionally set `UPDATE=true` to call `script/update` to perform database migrations when starting the service.
