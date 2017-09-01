# golang

To vendor golang package into your release, run:

```
$ bosh vendor-package golang-1.8-linux ~/workspace/bosh-packages/golang
```

Included packages:

- golang-1.8-linux
- golang-1.8-darwin

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

## TODO

- windows support
