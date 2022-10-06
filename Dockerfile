FROM ruby:3.1.2-slim-bullseye

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

ENV NODE_VERSION 14.20.0
ENV NPM_VERSION 8.16.0
ENV YARN_VERSION 1.22.0
ENV BUNDLE_PATH=/gems
ENV BUNDLE_WITHOUT="development test"
ENV BUNDLE_DEPLOYMENT=true
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /usr/src/app
COPY . .

RUN apt-get update -yq \
  && apt-get install gnupg wget -yq \
  && wget --quiet --output-document=- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google-archive.gpg \
  && bash -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  build-essential \
  google-chrome-stable \
  libpq-dev \
  libjemalloc2 \
  tar \
  tzdata \
  && wget "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && mkdir -p "/node-v${NODE_VERSION}-linux-x64" \
  && tar xzf "node-v$NODE_VERSION-linux-x64.tar.gz" --directory / \
  && npm i -g npm@$NPM_VERSION yarn@$YARN_VERSION \
  && npm cache clean --force \
  && rm -f "./node-v$NODE_VERSION-linux-x64.tar.gz" \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && apt-get autoremove \
  && chmod -R 755 ./bin/* \
  && chmod -R 755 ./build.sh \
  && bash ./build.sh

# enable jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
