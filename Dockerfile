# Local development image. Ruby and PostgreSQL run entirely in Docker.
FROM ruby:3.4-slim-bookworm

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev libvips && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
RUN chmod +x bin/rails bin/docker-entrypoint
EXPOSE 3000
ENTRYPOINT ["/app/bin/docker-entrypoint"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
