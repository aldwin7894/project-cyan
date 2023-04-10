FROM ruby:3.2.2-slim-bullseye AS build-env

ENV NODE_VERSION 18.12.0
ENV NPM_VERSION 8.16.0
ENV YARN_VERSION 1.22.0
ENV BUNDLE_PATH=/gems
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
  && rm -f "./node-v$NODE_VERSION-linux-x64.tar.gz"

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

RUN --mount=type=secret,id=TZ \
    --mount=type=secret,id=RAILS_ENV \
    --mount=type=secret,id=NODE_ENV \
    --mount=type=secret,id=OCCSON_ACCESS_TOKEN \
    --mount=type=secret,id=OCCSON_PASSPHRASE \
    --mount=type=secret,id=RAILS_MASTER_KEY \
    --mount=type=secret,id=RAILS_ASSET_HOST \
    chmod -R 755 ./bin/* \
    && chmod -R 755 ./build.sh \
    && bash ./build.sh

#==============================================
FROM ruby:3.2.2-slim-bullseye

ENV NODE_VERSION 18.12.0
ENV BUNDLE_PATH=/gems
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  gnupg \
  wget \
  && wget --quiet --output-document=- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft-edge-beta.gpg \
  && bash -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" >> /etc/apt/sources.list.d/microsoft-edge-beta.list' \
  && apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  microsoft-edge-beta \
  libjemalloc2 \
  tzdata \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get clean \
  && apt-get autoremove

WORKDIR /usr/src/app
COPY --from=build-env /usr/src/app .
COPY --from=build-env /usr/local/bundle /usr/local/bundle
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

HEALTHCHECK --interval=5m --timeout=10s --retries=5 --start-period=10s  \
  CMD wget --no-verbose --tries=1 --spider http://0.0.0.0:3000/ping || exit 1

# Configure the main process to run when running the image
CMD ["LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2", "bin/rails", "s", "-b", "0.0.0.0"]
