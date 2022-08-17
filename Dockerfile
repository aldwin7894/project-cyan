FROM ruby:3.1.0-slim-bullseye

ENV NODE_VERSION 14.20.0
ENV NPM_VERSION 8.16.0
ENV YARN_VERSION 1.22.0
ENV BUNDLE_PATH=/gems
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  build-essential \
  curl \
  libpq-dev \
  libjemalloc2 \
  tar \
  git \
  tzdata \
  && curl "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" -O \
  && tar xzf "node-v$NODE_VERSION-linux-x64.tar.gz" \
  && npm i -g npm@$NPM_VERSION yarn@$YARN_VERSION \
  && npm cache clean --force \
  && rm -f "/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && apt-get autoremove

# enable jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

COPY . /app
WORKDIR /app

RUN chmod -R 755 ./bin/* \
  && chmod -R 755 ./build.sh \
  && chmod -R 755 ./release-tasks.sh\
  && bash -v ./build.sh "${RAILS_ENV}" "${NODE_ENV}"

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
EXPOSE 3000
