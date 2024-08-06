FROM debian:12.6

ENV YQ_VERSION="4.44.2" \
    CERTIN_VERSION="0.3.5"

RUN apt update && \
    apt install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update

RUN apt install -y docker-ce docker-compose-plugin gettext

# fix ulimits because we want to do docker-in-docker
# see https://github.com/docker/cli/issues/4807#issuecomment-1903950217
RUN sed -i 's/cgroupfs_mount$/#cgroupfs_mount\n/' /etc/init.d/docker && \
    sed -i 's/ulimit -Hn/#ulimit -Hn/g' /etc/init.d/docker

RUN curl --fail -LO https://github.com/joemiller/certin/releases/download/v${CERTIN_VERSION}/certin_linux_amd64 && \
    chmod +x certin_linux_amd64 && \
    mv certin_linux_amd64 /usr/local/bin/certin && \
    certin version

RUN curl --fail -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.30.3/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin && \
    kubectl version --client

RUN mkdir /kindof

ADD compose.yaml.tpl /kindof/
ADD bootstrap.sh /kindof/
ADD entrypoint.sh /kindof/
ADD etc /kindof/etc/

# Kubernetes API
EXPOSE 32479

# etcd (plaintext)
EXPOSE 2380

WORKDIR /workdir

VOLUME /workdir

ENV ETCD_DATA_DIR=/etcd
VOLUME /etcd

ENTRYPOINT [ "/kindof/entrypoint.sh" ]
