# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.11
ARG NODE_VERSION=24.13.0
FROM node:${NODE_VERSION}-bookworm-slim AS node
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=2 \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    MALLOC_ARENA_MAX=2 \
    BOOTSNAP_CACHE_DIR=/tmp/bootsnap \
    HOME=/tmp

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 ca-certificates curl && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler -v 4.1.0.beta2 --no-document

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY package.json package-lock.json ./
RUN npm ci && npm cache clean --force

COPY . .
RUN mkdir -p tmp/pids storage log app/assets/builds && \
    SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile && \
    rm -rf node_modules tmp/* log/*

FROM base AS runtime

RUN groupadd --gid 1000 rails && \
    useradd --uid 1000 --gid rails --create-home --shell /usr/sbin/nologin rails && \
    mkdir -p storage tmp/pids log && \
    chown -R rails:rails storage tmp log

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

USER rails:rails
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
