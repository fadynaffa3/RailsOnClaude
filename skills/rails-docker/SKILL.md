---
name: rails-docker
description: Dockerfile optimization, docker-compose setup, multi-stage builds, development and production containers for Rails applications
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - docker
  - containers
  - docker-compose
  - deployment
dependencies:
  - rails >= 7.0
  - docker >= 20.10
  - docker-compose >= 2.0
---

# Rails Docker

A comprehensive guide for containerizing Ruby on Rails applications with Docker. This skill covers Dockerfile optimization, docker-compose setup, multi-stage builds, development environments, and production-ready containers.

## Use this skill when

- Containerizing a new Rails application
- Optimizing existing Docker setups
- Setting up development environments with Docker
- Creating production-ready Docker images
- Implementing multi-stage builds
- Setting up docker-compose for local development
- Configuring Docker for CI/CD pipelines
- Reducing Docker image sizes
- Improving Docker build times
- Setting up Docker health checks
- Managing secrets in containers
- Implementing hot-reloading in development
- Creating reproducible development environments

## Do not use this skill when

- Docker adds unnecessary complexity for your use case
- Deploying to platforms that handle containerization (Heroku, etc.)
- Simple scripts or one-off tasks
- You need direct hardware access

## Prerequisites

- Docker installed (20.10+)
- Docker Compose installed (2.0+)
- Rails application (7.0+)
- Basic understanding of Docker concepts
- Understanding of Linux basics

## Docker Architecture Overview

```
Project Structure:
├── Dockerfile              # Production image
├── Dockerfile.dev          # Development image (optional)
├── docker-compose.yml      # Local development
├── docker-compose.prod.yml # Production (optional)
├── .dockerignore          # Files to exclude
└── docker/
    ├── entrypoint.sh      # Container startup script
    ├── nginx.conf         # Nginx configuration (if using)
    └── wait-for-it.sh     # Service dependency script
```

## Step-by-Step Implementation

### Step 1: Create Production Dockerfile

#### Multi-Stage Build (Recommended)

```dockerfile
# Dockerfile

# Stage 1: Build dependencies
FROM ruby:3.2.2-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    nodejs \
    yarn \
    tzdata

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install -j$(nproc) && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
    find /usr/local/bundle/gems/ -name "*.o" -delete

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production && \
    yarn cache clean

# Copy application code
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile

# Stage 2: Runtime
FROM ruby:3.2.2-alpine

# Install runtime dependencies only
RUN apk add --no-cache \
    postgresql-client \
    tzdata \
    curl \
    bash

# Create app user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app

# Set working directory
WORKDIR /app

# Copy gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code and compiled assets
COPY --from=builder --chown=app:app /app /app

# Switch to non-root user
USER app

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

#### Single-Stage Build (Simpler but Larger)

```dockerfile
# Dockerfile

FROM ruby:3.2.2-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    postgresql-client \
    git \
    nodejs \
    yarn \
    tzdata \
    curl

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install -j$(nproc)

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production

# Copy application
COPY . .

# Precompile assets
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile

# Create non-root user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app && \
    chown -R app:app /app

USER app

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### Step 2: Create Development Dockerfile

```dockerfile
# Dockerfile.dev

FROM ruby:3.2.2

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    postgresql-client \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    vim && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install

# Copy application
COPY . .

# Expose port
EXPOSE 3000

# Start Rails server with hot-reloading
CMD rm -f tmp/pids/server.pid && \
    bundle exec rails server -b 0.0.0.0
```

### Step 3: Create .dockerignore

```
# .dockerignore

# Git
.git
.gitignore
.gitattributes

# CI/CD
.github
.gitlab-ci.yml
.travis.yml

# Documentation
README.md
CHANGELOG.md
*.md

# Environment
.env*
!.env.example

# Logs
log/*
tmp/*
!log/.keep
!tmp/.keep

# Storage
storage/*
!storage/.keep

# Node
node_modules
npm-debug.log
yarn-error.log

# Test
test/
spec/
coverage/
.rspec

# IDEs
.vscode
.idea
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Ruby
*.gem
.bundle
vendor/bundle

# Assets (will be compiled in container)
public/assets
public/packs
```

### Step 4: Create docker-compose.yml

```yaml
# docker-compose.yml

version: '3.9'

services:
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD:-password}
      POSTGRES_USER: ${DATABASE_USER:-postgres}
      POSTGRES_DB: ${DATABASE_NAME:-myapp_development}
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
      - node_modules:/app/node_modules
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/myapp_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
      RAILS_MAX_THREADS: 5
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    stdin_open: true
    tty: true

  sidekiq:
    build:
      context: .
      dockerfile: Dockerfile.dev
    command: bundle exec sidekiq
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/myapp_development
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
    depends_on:
      - db
      - redis

volumes:
  postgres_data:
  redis_data:
  bundle_cache:
  node_modules:
```

### Step 5: Create Entrypoint Script

```bash
#!/bin/bash
# docker/entrypoint.sh

set -e

# Remove pre-existing server.pid
rm -f /app/tmp/pids/server.pid

# Wait for database
until PGPASSWORD=$DATABASE_PASSWORD psql -h "db" -U "$DATABASE_USER" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - continuing"

# Run database migrations
bundle exec rails db:prepare

# Then exec the container's main process (what's set as CMD in Dockerfile)
exec "$@"
```

```bash
chmod +x docker/entrypoint.sh
```

Update Dockerfile to use entrypoint:

```dockerfile
# Add to Dockerfile
COPY docker/entrypoint.sh /usr/bin/
ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### Step 6: Optimize Build Performance

#### Use BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in docker-compose.yml
version: '3.9'
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - myapp:latest
      args:
        BUILDKIT_INLINE_CACHE: 1
```

#### Layer Caching Strategy

```dockerfile
# Dockerfile with optimized caching

FROM ruby:3.2.2-alpine AS builder

WORKDIR /app

# Layer 1: Install system dependencies (rarely changes)
RUN apk add --no-cache build-base postgresql-dev git nodejs yarn tzdata

# Layer 2: Install gems (changes when Gemfile changes)
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle install -j$(nproc)

# Layer 3: Install node modules (changes when package.json changes)
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production

# Layer 4: Copy application code (changes frequently)
COPY . .

# Layer 5: Precompile assets (changes when assets change)
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rails assets:precompile

# Runtime stage
FROM ruby:3.2.2-alpine
# ... rest of Dockerfile
```

#### Docker Compose with Caching

```yaml
# docker-compose.yml with caching

version: '3.9'

x-app: &app
  build:
    context: .
    cache_from:
      - myapp:latest
  volumes:
    - .:/app:cached
    - bundle_cache:/usr/local/bundle:delegated
    - node_modules:/app/node_modules:delegated
    - rails_cache:/app/tmp/cache:delegated

services:
  web:
    <<: *app
    command: bundle exec rails server -b 0.0.0.0
```

### Step 7: Production Configuration

#### docker-compose.prod.yml

```yaml
# docker-compose.prod.yml

version: '3.9'

services:
  web:
    image: myregistry.com/myapp:${VERSION:-latest}
    restart: unless-stopped
    environment:
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_LOG_TO_STDOUT: "true"
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    volumes:
      - ./docker/nginx.conf:/etc/nginx/nginx.conf:ro
      - static_files:/app/public:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web

volumes:
  static_files:
```

#### Nginx Configuration

```nginx
# docker/nginx.conf

upstream rails {
  server web:3000 fail_timeout=0;
}

server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

  root /app/public;

  # Serve static assets directly
  location ~ ^/(assets|packs)/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
    add_header ETag "";
  }

  # Health check endpoint
  location /health {
    access_log off;
    proxy_pass http://rails;
  }

  # Proxy to Rails
  location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://rails;

    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
  }

  # Error pages
  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root /app/public;
  }
}
```

### Step 8: CI/CD Integration

#### GitHub Actions

```yaml
# .github/workflows/docker.yml

name: Docker Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Step 9: Common Docker Commands

#### Development Workflow

```bash
# Build and start services
docker-compose up -d

# Build with no cache
docker-compose build --no-cache

# View logs
docker-compose logs -f web

# Run Rails console
docker-compose exec web rails console

# Run migrations
docker-compose exec web rails db:migrate

# Run tests
docker-compose exec web rails test

# Access container shell
docker-compose exec web bash

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Run one-off commands
docker-compose run --rm web rails db:seed
```

#### Production Deployment

```bash
# Build image
docker build -t myapp:latest .

# Tag for registry
docker tag myapp:latest registry.com/myapp:v1.0.0

# Push to registry
docker push registry.com/myapp:v1.0.0

# Deploy with docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Run migrations in production
docker-compose -f docker-compose.prod.yml run --rm web rails db:migrate

# View production logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Advanced Patterns

### 1. Multi-Platform Builds

```bash
# Build for multiple architectures
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest --push .
```

### 2. Docker Secrets

```yaml
# docker-compose.yml with secrets
version: '3.9'

services:
  web:
    image: myapp:latest
    secrets:
      - db_password
      - rails_master_key
    environment:
      DATABASE_PASSWORD_FILE: /run/secrets/db_password
      RAILS_MASTER_KEY_FILE: /run/secrets/rails_master_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  rails_master_key:
    file: ./config/master.key
```

### 3. Health Checks

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def show
    checks = {
      database: database_check,
      redis: redis_check,
      sidekiq: sidekiq_check
    }

    status = checks.values.all? ? :ok : :service_unavailable

    render json: {
      status: status,
      checks: checks,
      timestamp: Time.current
    }, status: status
  end

  private

  def database_check
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue StandardError
    false
  end

  def redis_check
    Redis.current.ping == 'PONG'
  rescue StandardError
    false
  end

  def sidekiq_check
    Sidekiq::ProcessSet.new.size > 0
  rescue StandardError
    false
  end
end

# config/routes.rb
get '/health', to: 'health#show'
```

### 4. Development with Debugging

```yaml
# docker-compose.yml with debugging support
services:
  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rdebug-ide --host 0.0.0.0 --port 1234 -- bin/rails server -b 0.0.0.0"
    ports:
      - "3000:3000"
      - "1234:1234" # Debugging port
    environment:
      - DEBUGGER=true
```

## Best Practices

### 1. Keep Images Small

```dockerfile
# Use Alpine images
FROM ruby:3.2.2-alpine

# Clean up after installations
RUN apk add --no-cache build-base && \
    bundle install && \
    apk del build-base

# Remove unnecessary files
RUN rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
    find /usr/local/bundle/gems/ -name "*.o" -delete
```

### 2. Use Non-Root Users

```dockerfile
# Create and use non-root user
RUN addgroup -g 1000 -S app && \
    adduser -u 1000 -S app -G app && \
    chown -R app:app /app

USER app
```

### 3. Leverage Build Cache

```dockerfile
# Copy dependency files first (changes less frequently)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code last (changes frequently)
COPY . .
```

### 4. Use Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

### 5. Proper Logging

```ruby
# config/environments/production.rb
config.logger = ActiveSupport::Logger.new(STDOUT)
config.log_level = :info
config.log_tags = [:request_id]
```

## Common Mistakes

### 1. Not Using .dockerignore

```
# Always create .dockerignore to exclude:
.git
node_modules
log/*
tmp/*
```

### 2. Running as Root

```dockerfile
# Bad
USER root

# Good
USER app
```

### 3. Not Pinning Versions

```dockerfile
# Bad
FROM ruby:latest

# Good
FROM ruby:3.2.2-alpine
```

### 4. Copying Everything

```dockerfile
# Bad
COPY . .

# Good - copy selectively
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY package.json yarn.lock ./
RUN yarn install
COPY . .
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs web

# Check if port is in use
lsof -i :3000

# Rebuild without cache
docker-compose build --no-cache web
```

### Database Connection Issues

```bash
# Check if database is ready
docker-compose exec db pg_isready

# Check DATABASE_URL
docker-compose exec web env | grep DATABASE_URL

# Manually create database
docker-compose exec web rails db:create
```

### Permission Issues

```bash
# Fix permissions on host
sudo chown -R $USER:$USER .

# Or run as root in container (not recommended)
docker-compose exec -u root web bash
```

## Conclusion

Docker provides:
- **Consistency** across environments
- **Isolation** of dependencies
- **Reproducibility** of builds
- **Scalability** in production
- **Developer experience** improvements

Key principles:
1. Keep images small
2. Use multi-stage builds
3. Leverage layer caching
4. Run as non-root user
5. Implement health checks
6. Use .dockerignore
7. Pin versions
8. Monitor and log properly

Remember: Docker is a tool, not a silver bullet. Use it when it solves real problems!
