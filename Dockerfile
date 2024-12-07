FROM ruby:3.3.6-slim-bookworm AS build-env

ENV BUNDLE_PATH=/gems
ENV NODE_VERSION=22.12.0

RUN apt-get update && apt-get install -yq --no-install-recommends \
  build-essential \
  curl \
  git \
  tar \
  wget \
  && curl --proto "=https" -fsSL https://deb.nodesource.com/setup_lts.x | bash -s -- ${NODE_VERSION} \
  && apt-get install -yq --no-install-recommends nodejs \
  && npm i -g --ignore-scripts npm yarn \
  && npm cache clean --force \
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
FROM ruby:3.3.6-slim-bookworm

ENV BUNDLE_PATH=/gems

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
