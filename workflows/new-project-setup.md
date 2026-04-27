# Workflow: New Rails Project Setup

Production-ready Rails project initialization with best practices.

## Overview

Set up a new Rails 8+ application with monitoring, testing, and code quality tools.

## Prerequisites

- Ruby 3.4+ installed
- Rails 8+ installed
- Claude Code with RailsOnClaude installed

## Steps

### 1. Create Rails Application

```bash
rails new myapp --api --database=mysql --skip-test
cd myapp
```

### 2. Add Essential Gems

```bash
# Add to Gemfile
gem "devise"
gem "devise-jwt"
gem "cancancan"
gem "rolify"
gem "paper_trail"
gem "solid_queue"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-rspec"
end

group :test do
  gem "simplecov", require: false
end

bundle install
```

### 3. Initialize Testing Framework

```bash
rails generate rspec:install
```

**In Claude Code:**
```
/ruby-help help me configure RSpec with FactoryBot and SimpleCov
```

### 4. Configure Linting

```bash
rubocop --auto-gen-config
```

**In Claude Code:**
```
/ruby-help help me configure RuboCop for Rails 8 with best practices
```

### 5. Initialize Git

```bash
git init
git add .
git commit -m "Initial Rails 8 setup with monitoring and testing"
```

### 6. Run Initial Audit

**In Claude Code:**
```
/rails-audit
```

Review `RAILS_AUDIT_REPORT.md` and address any initial issues.

### 7. Set Up Database

```bash
rails db:create
rails db:migrate
```

### 8. Create First Model (Example)

```bash
rails generate model User email:string name:string
rails db:migrate
```

**In Claude Code:**
```
/rails-help help me add authentication with Devise and JWT
```

### 9. Write Tests

**In Claude Code:**
```
/ruby-help help me write RSpec tests for the User model
```

### 10. Run Test Suite

```bash
bundle exec rspec
```

### 11. Configure CI/CD

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4
          bundler-cache: true
      - run: bundle exec rubocop
      - run: bundle exec rspec
```

## Verification Checklist

- [ ] Rails app runs without errors
- [ ] RSpec is configured and tests pass
- [ ] RuboCop runs with no major violations
- [ ] SimpleCov generates coverage reports
- [ ] Git repository initialized with meaningful commits
- [ ] Database migrations run successfully
- [ ] CI/CD pipeline is configured

## Next Steps

- Set up background jobs with Solid Queue
- Add API documentation with rswag
- Configure CORS for frontend integration
- Set up staging and production environments

## Skills Used

- `/rails-help` - Rails conventions and setup
- `/ruby-help` - Ruby best practices and configuration
- `/rails-audit` - Initial code quality check

## Estimated Time

45-60 minutes for complete setup
