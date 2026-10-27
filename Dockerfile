# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.11
ARG NODE_VERSION=24.22.1
FROM node:${NODE_VERSION}-bookworm-slim AS node
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base
WORKDIR /rails
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_DEPLOYMENT=1 BUNDLE_PATH=/usr/local/bundle \
    RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1 BOOTSNAP_CACHE_DIR=/tmp/bootsnap
RUN apt-get update -qq && apt-get install --no-install-recommends -y libpq5 ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler -v 4.0.23 --no-document

FROM base AS build
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libpq-dev git pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/ /usr/local/
RUN npm install --global npm@11.19.1
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && rm -rf /usr/local/bundle/ruby/*/cache
COPY . .
RUN mkdir -p tmp/pids storage log app/assets/builds \
    && SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile \
    && rm -rf node_modules tmp/* log/*

FROM base AS runtime
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails
RUN groupadd --gid 1000 rails && useradd --uid 1000 --gid rails --create-home rails \
    && mkdir -p storage tmp/pids log && chown -R rails:rails storage tmp log
USER rails:rails
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
