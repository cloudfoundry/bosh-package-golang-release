# golang

To vendor golang package into your release, run:

```
$ git clone https://github.com/bosh-packages/golang-release
$ cd ~/workspace/your-release
$ bosh vendor-package golang-1.8-linux ~/workspace/golang-release
```

Included packages:

- golang-1.8-linux
- golang-1.8-darwin
- golang-1.8-windows

To use `golang-*` package for compilation in your packaging script:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.8-linux/bosh/compile.env
go build ...
```

[advanced use] To use `golang-*` package at runtime in your job scripts:

```bash
#!/bin/bash -eu
source /var/vcap/packages/golang-1.8-linux/bosh/runtime.env
go run ...
```

## Development

To run tests `cd tests/ && BOSH_ENVIRONMENT=vbox ./run.sh`

