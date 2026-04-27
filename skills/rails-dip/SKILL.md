---
name: rails-dip
description: Using Dip (Docker Interaction Process) with Rails applications. Manage Docker Compose services, run Rails commands, database operations, and testing through the Dip CLI.
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - docker
  - dip
  - docker-compose
  - development
dependencies:
  - docker
  - docker-compose
  - dip >= 7.0
---

# Rails Dip (Docker Interaction Process)

A comprehensive guide for using Dip to manage Docker-based Rails development environments. Dip simplifies Docker Compose workflows with memorable commands and consistent developer experience.

## Use this skill when

- Setting up Docker-based Rails development environment
- Running Rails commands in Docker containers
- Managing database operations through Docker
- Running tests in isolated containers
- Executing background jobs in Docker
- Managing multiple services (Rails, PostgreSQL, Redis, etc.)
- Onboarding new developers with standardized setup
- Ensuring consistent development environments across team
- Running one-off commands in containers
- Managing Docker Compose services efficiently

## Do not use this skill when

- Working with non-Dockerized Rails applications
- Production deployments (use proper orchestration tools)
- You need Kubernetes-level orchestration
- Simple Rails apps without external services
- Docker is not available in the environment

## Prerequisites

- Docker installed (20.10+)
- Docker Compose installed (2.0+)
- Dip gem installed (`gem install dip`)
- Understanding of Docker basics
- Familiarity with Rails commands

## Core Concepts

### What is Dip?

Dip (Docker Interaction Process) is a CLI utility that provides a convenient way to interact with Docker Compose-based development environments. It replaces long `docker-compose exec` commands with short, memorable aliases.

### Benefits

- **Shorter commands**: `dip rails c` instead of `docker-compose exec web bundle exec rails c`
- **Consistency**: Standardized commands across projects
- **Convenience**: Built-in helpers for common tasks
- **Onboarding**: New developers can be productive quickly
- **Documentation**: Dip config serves as living documentation

## Step-by-Step Implementation

### Step 1: Install Dip

```bash
# Install Dip gem globally
gem install dip

# Verify installation
dip --version
```

### Step 2: Create dip.yml Configuration

```yaml
# dip.yml
version: '7.1'

# Define environment variables
environment:
  RAILS_ENV: development
  COMPOSE_FILE: docker-compose.yml

# Define interactions (commands)
interaction:
  # Provision command for first-time setup
  provision:
    description: Provision the application (build, setup database, install deps)
    service: web
    command: |
      bundle install
      yarn install
      rails db:prepare
      rails db:seed

  # Rails commands
  rails:
    description: Run Rails commands
    service: web
    command: bundle exec rails
    compose:
      run_options: [no-deps, rm]

  # Rails console
  console:
    description: Open Rails console
    service: web
    command: bundle exec rails console

  # Bundle commands
  bundle:
    description: Run Bundler commands
    service: web
    command: bundle

  # Database commands
  psql:
    description: Open PostgreSQL console
    service: postgres
    command: psql -U postgres -d myapp_development

  mysql:
    description: Open MySQL console
    service: mysql
    command: mysql -u root -ppassword myapp_development

  # RSpec commands
  rspec:
    description: Run RSpec tests
    service: web
    environment:
      RAILS_ENV: test
    command: bundle exec rspec
    compose:
      run_options: [no-deps, rm]

  # RuboCop commands
  rubocop:
    description: Run RuboCop
    service: web
    command: bundle exec rubocop
    compose:
      run_options: [no-deps, rm]

  # Yarn commands
  yarn:
    description: Run Yarn commands
    service: web
    command: yarn

  # Shell access
  bash:
    description: Open bash shell in web container
    service: web
    command: /bin/bash

  sh:
    description: Open sh shell in web container
    service: web
    command: /bin/sh

  # Background jobs (Sidekiq example)
  sidekiq:
    description: Start Sidekiq worker
    service: worker
    command: bundle exec sidekiq

  # Rake tasks
  rake:
    description: Run Rake tasks
    service: web
    command: bundle exec rake
```

### Step 3: Create Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.9'

x-app: &app
  build:
    context: .
    dockerfile: Dockerfile
    args:
      RUBY_VERSION: '3.2.0'
      BUNDLER_VERSION: '2.4.0'
  environment: &app-env
    DATABASE_URL: postgres://postgres:password@postgres:5432/myapp_development
    REDIS_URL: redis://redis:6379/0
    RAILS_ENV: ${RAILS_ENV:-development}
    RAILS_LOG_TO_STDOUT: 'true'
  volumes:
    - .:/app:cached
    - bundle_cache:/bundle
    - node_modules:/app/node_modules
    - rails_cache:/app/tmp/cache
  tmpfs:
    - /tmp
    - /app/tmp/pids

services:
  web:
    <<: *app
    command: bundle exec rails server -b 0.0.0.0
    ports:
      - '3000:3000'
    depends_on:
      - postgres
      - redis
    stdin_open: true
    tty: true

  worker:
    <<: *app
    command: bundle exec sidekiq
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: myapp_development
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data

volumes:
  bundle_cache:
  node_modules:
  rails_cache:
  postgres_data:
  redis_data:
```

### Step 4: Create Dockerfile

```dockerfile
# Dockerfile
ARG RUBY_VERSION=3.2.0
FROM ruby:${RUBY_VERSION}-slim

ARG BUNDLER_VERSION=2.4.0

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      build-essential \
      libpq-dev \
      nodejs \
      yarn \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler -v ${BUNDLER_VERSION}

# Copy dependency files
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle config set --local path '/bundle' && \
    bundle install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start command (overridden by docker-compose)
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

## Common Dip Commands

### First-Time Setup

```bash
# Provision entire application (first time)
dip provision

# Start all services
dip up

# Start services in detached mode
dip up -d

# Stop all services
dip down

# Stop and remove volumes
dip down -v
```

### Rails Commands

```bash
# Rails console
dip rails console
# or shorthand
dip console

# Generate migration
dip rails generate migration AddEmailToUsers email:string

# Run migrations
dip rails db:migrate

# Rollback migration
dip rails db:rollback

# Reset database
dip rails db:reset

# Load seeds
dip rails db:seed

# Rails runner
dip rails runner 'User.count'

# Rails routes
dip rails routes

# Rails credentials
dip rails credentials:edit
```

### Database Commands

```bash
# Open PostgreSQL console
dip psql

# Create database
dip rails db:create

# Drop database
dip rails db:drop

# Migrate and seed
dip rails db:setup

# Prepare database (create + migrate or migrate if exists)
dip rails db:prepare

# Database console
dip rails dbconsole

# Dump database
dip psql -c "pg_dump myapp_development > backup.sql"

# Load database dump
dip psql myapp_development < backup.sql
```

### Running Tests

```bash
# Run all tests
dip rspec

# Run specific test file
dip rspec spec/models/user_spec.rb

# Run specific test by line
dip rspec spec/models/user_spec.rb:42

# Run tests with coverage
COVERAGE=true dip rspec

# Run specific tag
dip rspec --tag focus

# Run tests in parallel
dip rspec --parallel
```

### Code Quality

```bash
# Run RuboCop
dip rubocop

# Auto-fix RuboCop violations
dip rubocop -A

# Check specific files
dip rubocop app/models/user.rb

# Generate RuboCop todo file
dip rubocop --auto-gen-config
```

### Bundler Commands

```bash
# Install gems
dip bundle install

# Update gems
dip bundle update

# Update specific gem
dip bundle update rails

# Add gem
# Edit Gemfile, then:
dip bundle install

# Check for outdated gems
dip bundle outdated

# Show gem info
dip bundle show rails
```

### Asset Management

```bash
# Install JavaScript dependencies
dip yarn install

# Add package
dip yarn add react

# Build assets
dip rails assets:precompile

# Clean assets
dip rails assets:clean
```

### Container Management

```bash
# Open bash shell
dip bash

# Execute one-off command
dip rails runner 'puts Rails.env'

# View logs
docker-compose logs -f web

# View logs for all services
docker-compose logs -f

# Restart service
docker-compose restart web

# Rebuild containers
docker-compose build

# Rebuild and start
dip up --build
```

## Advanced Dip Configurations

### Environment-Specific Commands

```yaml
# dip.yml
interaction:
  # Production-like environment
  prod:
    description: Run in production-like environment
    service: web
    environment:
      RAILS_ENV: production
      SECRET_KEY_BASE: test123
    command: bundle exec rails

  # Staging commands
  staging:
    description: Run in staging environment
    service: web
    environment:
      RAILS_ENV: staging
    command: bundle exec rails
```

### Custom Helper Commands

```yaml
# dip.yml
interaction:
  # Reset everything and start fresh
  reset:
    description: Reset entire application (dangerous!)
    service: web
    command: |
      rails db:drop
      rails db:create
      rails db:migrate
      rails db:seed

  # Run full test suite with coverage
  test:
    description: Run full test suite with coverage
    service: web
    environment:
      RAILS_ENV: test
      COVERAGE: 'true'
    command: |
      rails db:test:prepare
      bundle exec rspec
      bundle exec rubocop

  # Generate sample data
  sample_data:
    description: Generate sample development data
    service: web
    command: rails db:seed:sample

  # Clean up development environment
  clean:
    description: Clean up development environment
    service: web
    command: |
      rails tmp:clear
      rails log:clear
      rails assets:clobber
```

### Multiple Database Support

```yaml
# dip.yml
interaction:
  # Primary database
  psql_primary:
    description: Open primary database console
    service: postgres_primary
    command: psql -U postgres -d myapp_development

  # Analytics database
  psql_analytics:
    description: Open analytics database console
    service: postgres_analytics
    command: psql -U postgres -d analytics_development

  # Migrate all databases
  db_migrate_all:
    description: Migrate all databases
    service: web
    command: |
      rails db:migrate
      rails db:migrate:analytics
```

## Best Practices

### 1. Use dip provision for Setup

```yaml
# dip.yml
interaction:
  provision:
    description: Setup application for first time
    service: web
    command: |
      echo "Installing dependencies..."
      bundle install
      yarn install
      echo "Setting up database..."
      rails db:prepare
      rails db:seed
      echo "Setup complete!"
```

### 2. Document Custom Commands

```yaml
# dip.yml - Good: Clear descriptions
interaction:
  test:
    description: Run full test suite with coverage report
    service: web
    command: bundle exec rspec

  # Bad: No description
  t:
    service: web
    command: bundle exec rspec
```

### 3. Use Compose Run Options

```yaml
# dip.yml
interaction:
  rspec:
    description: Run RSpec tests
    service: web
    compose:
      run_options: [no-deps, rm]  # Don't start deps, remove container after
    command: bundle exec rspec
```

### 4. Environment Variable Management

```yaml
# dip.yml
environment:
  RAILS_ENV: ${RAILS_ENV:-development}  # Default to development
  DATABASE_URL: postgres://postgres:password@postgres:5432/myapp_${RAILS_ENV}
```

### 5. Keep dip.yml Versioned

```bash
# Always commit dip.yml to version control
git add dip.yml
git commit -m "Add Dip configuration"
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs web

# Rebuild container
docker-compose build web

# Remove and recreate
docker-compose down
docker-compose up --build
```

### Permission Issues

```bash
# Fix file ownership
docker-compose run --rm web chown -R $(id -u):$(id -g) .

# Or in dip.yml
interaction:
  fix_permissions:
    description: Fix file ownership issues
    service: web
    command: chown -R $(id -u):$(id -g) /app
```

### Database Connection Issues

```bash
# Check if postgres is running
docker-compose ps postgres

# Restart postgres
docker-compose restart postgres

# Check database exists
dip psql -l

# Recreate database
dip rails db:drop db:create db:migrate
```

### Port Already in Use

```yaml
# docker-compose.yml - Use different ports
services:
  web:
    ports:
      - '3001:3000'  # Host:Container
```

## Comparison with Raw Docker Compose

```bash
# Without Dip
docker-compose exec web bundle exec rails console

# With Dip
dip console

# Without Dip
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb

# With Dip
dip rspec spec/models/user_spec.rb

# Without Dip
docker-compose exec postgres psql -U postgres -d myapp_development

# With Dip
dip psql
```

## Common Mistakes

### 1. Not Using provision

```bash
# Bad: Manual setup
dip bundle install
dip yarn install
dip rails db:create
dip rails db:migrate
dip rails db:seed

# Good: Use provision
dip provision
```

### 2. Forgetting to Rebuild

```bash
# Bad: Changes to Gemfile/Dockerfile not reflected
dip up

# Good: Rebuild after dependency changes
dip up --build
```

### 3. Not Cleaning Up Volumes

```bash
# Bad: Old data causing issues
dip down
dip up

# Good: Clean slate
dip down -v  # Remove volumes
dip up
```

## Complete Example: New Developer Onboarding

```bash
# 1. Clone repository
git clone https://github.com/company/project.git
cd project

# 2. Install Dip
gem install dip

# 3. Copy environment file
cp .env.example .env

# 4. Provision application
dip provision

# 5. Start services
dip up -d

# 6. Verify everything works
dip rails console
# => Should open Rails console

# 7. Run tests
dip rspec

# Developer is now ready to work!
```

## Conclusion

Dip simplifies Docker-based Rails development by:
- Providing memorable command aliases
- Standardizing workflows across team
- Reducing onboarding time
- Documenting common tasks
- Making Docker Compose more accessible

Remember: Keep `dip.yml` updated, document custom commands, and use `dip provision` for new developer setup.
