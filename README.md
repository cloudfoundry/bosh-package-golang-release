# golang

Note: requires bosh-cli version `v2.0.36`+ to `vendor-package` and `create-release`.

To vendor golang package into your release, run:

```
$ git clone https://github.com/cloudfoundry/bosh-package-golang-release
$ cd ~/workspace/your-release
$ bosh vendor-package golang-1.26-linux ~/workspace/bosh-package-golang-release
```

Included packages:

- `golang-1-{linux,darwin,windows}`: updated with latest version of go 1.x
- `golang-1.25-{linux,darwin,windows}`: updated with latest version of go 1.25.x
- `golang-1.26-{linux,darwin,windows}`: updated with latest version of go 1.26.x
- `fips-golang-1.26-linux`: FIPS 140-3 variant of go 1.26.x (see [FIPS 140-3 Support](#fips-140-3-support))

To use `golang-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.26-linux/bosh/compile.env
go build ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.26-windows\bosh\compile.ps1
go build ...
```
[advanced use] To use `golang-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.26-linux/bosh/runtime.env
go run ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.26-windows\bosh\runtime.ps1
go run ...
```

## FIPS 140-3 Support

Starting with Go 1.24, the Go standard library includes a native FIPS 140-3 validated
cryptographic module ([CMVP Certificate #5247](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/5247)).
This repository provides FIPS variant packages that compile Go binaries with the certified
crypto module embedded and FIPS mode enabled by default.

FIPS packages use the `fips-` prefix naming convention (e.g. `fips-golang-1.26-linux`)
which integrates with the `PREFIX` parameter in the shared CI tasks from
`wg-app-platform-runtime-ci`.

To vendor the FIPS package into your release:

```
$ bosh vendor-package fips-golang-1.26-linux ~/workspace/bosh-package-golang-release
```

To use it in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/fips-golang-1.26-linux/bosh/compile.env
go build ...
```

Or using a glob (for forward-compatible version bumps):

```bash
#!/bin/bash -eu
source /var/vcap/packages/fips-golang-*-linux/bosh/compile.env
go build ...
```

The FIPS compile environment sets:
- `GOFIPS140=v1.0.0` - embeds the CMVP-certified crypto module snapshot (v1.0.0)
- `-tags=fips140` - sets `DefaultGODEBUG=fips140=on`, activating FIPS at runtime

Binaries built with this package will:
- Perform integrity self-checks at initialization
- Run known-answer self-tests (KATs) for all crypto algorithms
- Use NIST SP 800-90A DRBG for random number generation
- Restrict TLS to FIPS-approved cipher suites and protocol versions
- No code changes are required in consuming releases

### Verifying FIPS mode

After deploying a binary built with the FIPS package, verify with:

```bash
$ strings /var/vcap/packages/<package>/bin/<binary> | grep "fips140=on"
build   DefaultGODEBUG=...,fips140=on,...
```

### CI integration

The shared `bump-golang-package-name` task in `wg-app-platform-runtime-ci` supports
FIPS packages via the `PREFIX` parameter:

```yaml
- task: bump-golang-package-name-fips-linux
  file: ci/shared/tasks/bump-golang-package-name/linux.yml
  params:
    PLATFORM: linux
    PREFIX: fips
```

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

## Adding a new golang line

To add a new line, edit the variable in the top of `dev/add-line`
Execute the script, commit changes, and update the pipeline.

The blobs necessary for the new version line will automatically be added via CI. The `build-docker-image` job will fail until the blobs are added by the `bump` job.

### Windows

You will need to set the following variables, for example:

```
export STEMCELL_PATH="/path/to/windows/stemcell.zip"
export STEMCELL_VERSION="<version>"
export OS="windows2019"
export JOB_NAME="test-windows"
export VM_EXTENSIONS="[50GB_ephemeral_disk]"
```

## Shared Concourse tasks

This repository provides a couple helpful Concourse tasks in `ci/tasks/shared` that can help keep the Golang package vendored in your BOSH release up to date, and bump dependencies.

### ci/tasks/shared/bump-golang-package

The `bump-golang-package` task runs `bosh vendor-package` to automatically update the version of Golang vendored into your own BOSH release.

* `GIT_USER_NAME`: Required. The email that will be used to generate commits.
* `GIT_USER_EMAIL`: Required. The user name that will be used to generate commits.
* `PACKAGES`: Required. Specifies Golang packages will be vendored into your own BOSH release, e.g. the `golang-1-linux` package.
* `PACKAGES_TO_REMOVE`: Optional. A list of packages to remove from the release. This can be useful if one is bumping from `golang-1.x-linux` to `golang-1.y-linux` and `1.y` is intended to replace `1.x`/
* `PRIVATE_YML`: Required. The contents of config/private.yml for your own BOSH release. Necessary to run `bosh vendor-package`.
* `RELEASE_DIR`: Required. The directory where your release has been cloned on disk.

### ci/tasks/shared/bump-deps

The `bump-deps` task will update to go version specified in `go.mod` and then run `go get -u ./...`, and if a `tools` package is present `go get -u ./tools` in the `$SOURCE_PATH` directory specified.

* `GIT_USER_NAME`: Required. The email that will be used to generate commits.
* `GIT_USER_EMAIL`: Required. The user name that will be used to generate commits.
* `GO_PACKAGE`: Required. The location of the vendored Golang package to be used when running `go` commands.
* `SOURCE_PATH`: Required. The location of the Golang source you wish to update. Must contain a `go.mod` file. 
