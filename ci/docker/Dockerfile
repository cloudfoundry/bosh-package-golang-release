FROM ubuntu:bionic

COPY --from=bosh/bosh-ecosystem-concourse:latest /usr/local/bin/bosh /usr/local/bin/bosh

RUN apt-get update && \
    apt-get install -y \
        curl \
        git \
        jq
