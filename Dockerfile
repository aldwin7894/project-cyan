FROM ruby:3.3.5-slim-bookworm AS build-env

ENV NODE_VERSION=20.17.0
ENV NPM_VERSION=10.8
ENV YARN_VERSION=1.22
ENV BUNDLE_PATH=/gems
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  build-essential \
  git \
  tar \
  wget \
  && wget --quiet "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" --max-redirect=0 \
  && mkdir -p "/node-v${NODE_VERSION}-linux-x64" \
  && tar xzf "node-v$NODE_VERSION-linux-x64.tar.gz" --directory / \
  && npm i -g "npm@$NPM_VERSION" "yarn@$YARN_VERSION" \
  && npm cache clean --force \
  && rm -f "./node-v$NODE_VERSION-linux-x64.tar.gz" \
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
COPY entrypoint.sh .
COPY entrypoint-sidekiq.sh .

RUN --mount=type=secret,id=TZ \
  --mount=type=secret,id=RAILS_ENV \
  --mount=type=secret,id=NODE_ENV \
  --mount=type=secret,id=RAILS_MASTER_KEY \
  --mount=type=secret,id=RAILS_ASSET_HOST \
  chmod -R 755 ./bin/* \
  && chmod -R 755 ./build.sh \
  && bash ./build.sh

#==============================================
FROM ruby:3.3.5-slim-bookworm

ENV NODE_VERSION=20.17.0
ENV BUNDLE_PATH=/gems
ENV PATH="/node-v${NODE_VERSION}-linux-x64/bin:${PATH}"

# Install MS Edge for Ferrum
# && wget --quiet --output-document=- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft-edge-beta.gpg \
# && bash -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" >> /etc/apt/sources.list.d/microsoft-edge-beta.list' \
# && apt get install microsoft-edge-beta

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends \
  gnupg \
  libjemalloc2 \
  patchelf \
  tzdata \
  wget \
  && patchelf --add-needed libjemalloc.so.2 /usr/local/bin/ruby \
  && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
  && apt-get purge patchelf -y \
  && apt-get clean \
  && apt-get autoremove

WORKDIR /usr/src/app
COPY --from=build-env /usr/src/app .
COPY --from=build-env /usr/local/bundle /usr/local/bundle
COPY --from=build-env /gems /gems
COPY --from=build-env "/node-v${NODE_VERSION}-linux-x64" "/node-v${NODE_VERSION}-linux-x64"

# Configure jemalloc
ENV MALLOC_CONF='narenas:2,background_thread:true,thp:never,dirty_decay_ms:1000,muzzy_decay_ms:0'

# Add a script to be executed every time the container starts.
RUN chmod +x ./entrypoint.sh \
  && chmod +x ./entrypoint-sidekiq.sh \
  && groupadd -r docker && useradd -r -g docker docker \
  && chown -R docker:docker /usr/src/app
USER docker
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
EXPOSE 3000

HEALTHCHECK --interval=5m --timeout=10s --retries=5 --start-period=10s  \
  CMD ["wget", "--no-verbose", "--tries=1", "--spider", "http://web:3000/ping"]

# Configure the main process to run when running the image
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
