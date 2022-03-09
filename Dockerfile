FROM ruby:3.1.0-slim-bullseye

ENV NODE_VERSION 14.18.2
ENV NPM_VERSION 6.14.15
ENV YARN_VERSION 1.22
ENV NVM_DIR /usr/local/nvm
ENV BUNDLE_PATH=/gems

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  build-essential \
  curl \
  libpq-dev \
  libjemalloc2 \
  postgresql-client \
  git \
  tzdata \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash \
  && . ~/.bashrc \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default \
  && npm i -g npm@$NPM_VERSION yarn@$YARN_VERSION

# enable jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

COPY . /app
WORKDIR /app

RUN chmod -R 755 ./bin/* \
  && chmod -R 755 ./build.sh \
  && chmod -R 755 ./release-tasks.sh\
  && bash -v ./build.sh "${RAILS_ENV}" "${NODE_ENV}"

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
EXPOSE 3000
