# # For Production
# $ docker build --build-arg RAILS_ENV=production -t unified-flash-messages-production:latest .
#
# # For Staging
# $ docker build --build-arg RAILS_ENV=staging -t unified-flash-messages-staging:latest .
#
# # For Development
# $ docker build --build-arg RAILS_ENV=development -t unified-flash-messages-development:latest .

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.5

FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

ARG RAILS_ENV

# Rails app lives here
WORKDIR /rails

# Set environment with flexibility for staging/production
ENV BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV=$RAILS_ENV

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and run the application
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  build-essential \
  pkg-config \
  libyaml-dev \
  libsqlite3-dev \
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN if [ "$RAILS_ENV" = "development" ]; then \
      bundle config unset --local without; \
      bundle install; \
    else \
      bundle config set --local without 'development test'; \
      bundle config set deployment true; \
      bundle install; \
    fi && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile -j 0 --gemfile app/ lib/ config/

# Precompiling assets without requiring secret RAILS_MASTER_KEY
RUN if [ "$RAILS_ENV" != "development" ]; then \
      SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
    else \
      echo "Skip assets:precompile in development"; \
    fi

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  curl \
  libsqlite3-0 \
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /rails/db /rails/log /rails/storage /rails/tmp && \
    chown -R rails:rails /rails /usr/local/bundle
USER rails:rails

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server with thruster for production/staging.
# Puma listening on port to THRUSTER_TARGET_PORT,
# kamal-proxy THRUSTER_HTTP_PORT for Thruster
ARG THRUSTER_HTTP_PORT=3001
ARG THRUSTER_TARGET_PORT=3000

ENV THRUSTER_HTTP_PORT=${THRUSTER_HTTP_PORT} \
    THRUSTER_TARGET_PORT=${THRUSTER_TARGET_PORT} \
    THRUSTER_DEBUG=1 \
    PORT=${THRUSTER_TARGET_PORT}

EXPOSE ${PORT}
CMD ["bundle", "exec", "thrust", "bin/rails", "server"]
