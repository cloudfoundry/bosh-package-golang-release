LABEL org.opencontainers.image.source=https://github.com/cloudfoundry/bosh-package-golang-release

FROM ubuntu:jammy

RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        curl \
        git \
        git-lfs \
        gnupg \
        jq \
        lsb-release \
        wget

RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install trivy
