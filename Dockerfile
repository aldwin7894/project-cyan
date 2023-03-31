FROM ruby:3.2.2-slim-bullseye AS build-env

ARG TZ_ARG
ARG RAILS_ENV_ARG
ARG NODE_ENV_ARG
ARG OCCSON_ACCESS_TOKEN_ARG
ARG OCCSON_PASSPHRASE_ARG
ARG RAILS_MASTER_KEY_ARG
ARG RAILS_ASSET_HOST_ARG

ENV TZ=$TZ_ARG
ENV RAILS_ENV=$RAILS_ENV_ARG
ENV NODE_ENV=$NODE_ENV_ARG
ENV OCCSON_ACCESS_TOKEN=$OCCSON_ACCESS_TOKEN_ARG
ENV OCCSON_PASSPHRASE=$OCCSON_PASSPHRASE_ARG
ENV RAILS_MASTER_KEY=$RAILS_MASTER_KEY_ARG
ENV RAILS_ASSET_HOST=$RAILS_ASSET_HOST_ARG

ENV NODE_VERSION 18.12.0
ENV NPM_VERSION 8.16.0
ENV YARN_VERSION 1.22.0
ENV BUNDLE_PATH=/gems
ENV BUNDLE_WITHOUT="development test"
ENV BUNDLE_DEPLOYMENT=true
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  wget \
  build-essential \
  libpq-dev \
  tar \
  git \
  && wget --quiet "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && mkdir -p "/node-v${NODE_VERSION}-linux-x64" \
  && tar xzf "node-v$NODE_VERSION-linux-x64.tar.gz" --directory / \
  && npm i -g npm@$NPM_VERSION yarn@$YARN_VERSION \
  && npm cache clean --force \
  && rm -f "./node-v$NODE_VERSION-linux-x64.tar.gz" \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && apt-get autoremove

WORKDIR /usr/src/app
COPY app/ ./app/
COPY bin/ ./bin/
COPY config/ ./config/
COPY db/ ./db/
COPY lib/ ./lib/
COPY log/ ./log/
COPY public/ ./public/
COPY storage/ ./storage/
COPY test/ ./test/
COPY tmp/ ./tmp/
COPY vendor/ ./vendor/
COPY Gemfile* .
COPY yarn.lock .
COPY .* .
COPY *.js .
COPY *.json .
COPY Rakefile .
COPY build.sh .
COPY config.ru .

RUN chmod -R 755 ./bin/* \
  && chmod -R 755 ./build.sh \
  && bash ./build.sh

#==============================================
FROM ruby:3.2.2-slim-bullseye

ARG TZ_ARG
ARG RAILS_ENV_ARG
ARG NODE_ENV_ARG
ARG OCCSON_ACCESS_TOKEN_ARG
ARG OCCSON_PASSPHRASE_ARG
ARG RAILS_MASTER_KEY_ARG
ARG RAILS_ASSET_HOST_ARG

ENV TZ=$TZ_ARG
ENV RAILS_ENV=$RAILS_ENV_ARG
ENV NODE_ENV=$NODE_ENV_ARG
ENV OCCSON_ACCESS_TOKEN=$OCCSON_ACCESS_TOKEN_ARG
ENV OCCSON_PASSPHRASE=$OCCSON_PASSPHRASE_ARG
ENV RAILS_MASTER_KEY=$RAILS_MASTER_KEY_ARG
ENV RAILS_ASSET_HOST=$RAILS_ASSET_HOST_ARG

ENV NODE_VERSION 18.12.0
ENV BUNDLE_PATH=/gems
ENV BUNDLE_WITHOUT="development test"
ENV BUNDLE_DEPLOYMENT=true
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"

RUN apt-get update -yq \
  && apt-get install gnupg wget -yq --no-install-recommends \
  && wget --quiet --output-document=- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google-archive.gpg \
  && bash -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  google-chrome-stable \
  libjemalloc2 \
  tzdata \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && apt-get autoremove

# enable jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

WORKDIR /usr/src/app
COPY --from=build-env /usr/src/app .
COPY --from=build-env /gems /gems
COPY --from=build-env "/node-v${NODE_VERSION}-linux-x64" "/node-v${NODE_VERSION}-linux-x64"

# Add a script to be executed every time the container starts.
COPY entrypoint.sh .
RUN chmod +x ./entrypoint.sh
RUN groupadd -r docker && useradd -r -g docker docker
RUN chown -R docker:docker /usr/src/app
USER docker
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
