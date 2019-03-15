# golang

Note: requires bosh-cli version `v2.0.36`+ to `vendor-package` and `create-release`.

To vendor golang package into your release, run:

```
$ git clone https://github.com/bosh-packages/golang-release
$ cd ~/workspace/your-release
$ bosh vendor-package golang-1.12-linux ~/workspace/golang-release
```

Included packages:

- `golang-1-{linux,darwin,windows}`: updated with latest version of go 1.x
- `golang-1.12-{linux,darwin,windows}`: updated with latest version of go 1.12.x
- `golang-1.11-{linux,darwin,windows}`: updated with latest version of go 1.11.x

To use `golang-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.12-linux/bosh/compile.env
go build ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.12-windows\bosh\compile.ps1
go build ...
```
[advanced use] To use `golang-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.12-linux/bosh/runtime.env
go run ...
```
or on Windows:

```powershell
. C:\var\vcap\packages\golang-1.12-windows\bosh\runtime.ps1
go build ...
```

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`
