FROM	debian:wheezy
#
# Esta imagem da qual herdo as funcionalidades inclui o Debian 8
#
MAINTAINER João Antonio Ferreira "joao.parana@gmail.com"

ENV REFRESHED_AT 2015-12-01

RUN mkdir -p /calypso

RUN  apt-get -y update && apt-get -y install \
     curl \
     wget \
     git \
     python \
     make \
     build-essential

# usar a Release do Calypso no Github
WORKDIR /setup
ENV CALYPSO_VERSION INITIAL_COMMIT
RUN curl -o $CALYPSO_VERSION.tar.gz \
        https://codeload.github.com/Automattic/wp-calypso/tar.gz/$CALYPSO_VERSION && \
    tar -xzf $CALYPSO_VERSION.tar.gz && \
    cd wp-calypso-$CALYPSO_VERSION && \
    mv .dockerignore .esformatter .eslintrc .jsfmtrc .rtlcssrc .editorconfig /calypso && \
    mv .eslintignore .gitignore .npmrc /calypso && \
    mv * /calypso && \
    ls -lAt .

WORKDIR /calypso

RUN  mkdir -p /tmp
COPY ./env-config.sh /tmp/
RUN  bash /tmp/env-config.sh

ENV NODE_VERSION 0.12.6
RUN curl -O https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz && \
    tar -zxf node-v$NODE_VERSION-linux-x64.tar.gz -C /usr/local && \
    ln -sf node-v$NODE_VERSION-linux-x64 /usr/local/node && \
    ln -sf /usr/local/node/bin/npm /usr/local/bin/ && \
    ln -sf /usr/local/node/bin/node /usr/local/bin/ && \
    rm node-v$NODE_VERSION-linux-x64.tar.gz

ENV NODE_PATH /calypso/server:/calypso/shared

# Install base npm packages to take advantage of the docker cache
# COPY ./package.json /calypso/package.json

RUN npm install --production

# Build javascript bundles for each environment and change ownership
RUN CALYPSO_ENV=wpcalypso make build-wpcalypso
RUN CALYPSO_ENV=horizon make build-horizon
RUN CALYPSO_ENV=stage make build-stage
RUN CALYPSO_ENV=production make build-production

USER nobody
RUN chown -R nobody /calypso

# CMD NODE_ENV=production node build/bundle-$CALYPSO_ENV.js
CMD ["/bin/bash"]
