FROM microsoft/azure-cli

MAINTAINER Aaron Walker <a.walker@base2services.com>

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
    && \curl -sSL https://get.rvm.io | bash -s stable --ruby

RUN curl -sSL https://get.docker.com/ | sh \
    && curl -L https://github.com/docker/compose/releases/download/1.5.1/run.sh > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

ADD . /opt/ciinabox
WORKDIR /opt/ciinabox

VOLUME ["/opt/ciinabox/ciinaboxes"]
