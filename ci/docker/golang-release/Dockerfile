# BuildKit sets TARGETARCH (amd64 or arm64). bosh/integration is amd64-only, so
# arm64 takes the bosh CLI from its release binary instead.
ARG TARGETARCH

FROM bosh/integration:latest AS bosh-cli-amd64

FROM ubuntu:jammy AS bosh-cli-arm64
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl jq && \
    url="$(curl -s https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest \
      | jq -r '.assets[] | select(.name | endswith("-linux-arm64")) | .browser_download_url')" && \
    curl --show-error -sL "${url}" -o /usr/bin/bosh && \
    chmod +x /usr/bin/bosh

FROM bosh-cli-${TARGETARCH} AS bosh-cli

FROM ubuntu:jammy

COPY --from=bosh-cli /usr/bin/bosh /usr/local/bin/bosh

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        ca-certificates \
        curl \
        gcc \
        git \
        git-lfs \
        jq

ADD . /tmp/release

RUN cd /tmp/release && \
    bosh sync-blobs && \
    mkdir -p /var/vcap/packages && mkdir -p /var/vcap/data && \
    for package in $(ls /tmp/release/packages | grep linux | grep -v test); do \
        rm -rf /tmp/workspace && \
        mkdir /tmp/workspace && \
        cp -r /tmp/release/src/* /tmp/workspace/ && \
        blob_filename=$(bosh int /tmp/release/packages/$package/spec --path /files | grep -o "go1.*.tar.gz") && \
        cp /tmp/release/blobs/${blob_filename} /tmp/workspace && \
        chmod +x /tmp/release/packages/$package/packaging && \
        mkdir -p /var/vcap/packages/$package && \
        cd /tmp/workspace && \
        BOSH_INSTALL_TARGET=/var/vcap/packages/$package /tmp/release/packages/$package/packaging && \
        cd /tmp; \
    done && \
    rm -r /tmp/release /tmp/workspace

# Default Golang environment to golang-1-linux. These values are pulled from the
# src/1/compile.env.linux environment file.
ENV GOROOT "/var/vcap/packages/golang-1-linux"
ENV GOCACHE "/var/vcap/data/golang-1-linux/cache"
ENV PATH "$GOROOT/bin:$PATH"
