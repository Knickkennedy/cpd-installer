FROM quay.io/podman/stable:latest

RUN yum -y update && \
    yum clean all && \
    yum -y install fuse python3 python3-pip && \
    pip3 install --upgrade pip && \
    python3 -m pip install ansible kubernetes PyYAML jsonpatch

WORKDIR /home/podman

COPY . /home/podman/

RUN tar --no-same-owner --no-same-permissions -xzf cpd-cli-linux-SE-13.1.5.tgz \
    && rm cpd-cli-linux-SE-13.1.5.tgz \
    && mv cpd-cli-*/* /usr/local/bin/ \
    && tar -xvf oc.tar \
    && mv oc /usr/local/bin/