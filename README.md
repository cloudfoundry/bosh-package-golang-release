# golang

Note: requires bosh-cli version `v2.0.36`+ to `vendor-package` and `create-release`.

To vendor golang package into your release, run:

```
$ git clone https://github.com/cloudfoundry/bosh-package-golang-release
$ cd ~/workspace/your-release
$ bosh vendor-package golang-1.21-linux ~/workspace/bosh-package-golang-release
```

Included packages:

- `golang-1-{linux,darwin,windows}`: updated with latest version of go 1.x
- `golang-1.20-{linux,darwin,windows}`: updated with latest version of go 1.20.x
- `golang-1.21-{linux,darwin,windows}`: updated with latest version of go 1.21.x

To use `golang-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.21-linux/bosh/compile.env
go build ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.21-windows\bosh\compile.ps1
go build ...
```
[advanced use] To use `golang-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.21-linux/bosh/runtime.env
go run ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.21-windows\bosh\runtime.ps1
go run ...
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
