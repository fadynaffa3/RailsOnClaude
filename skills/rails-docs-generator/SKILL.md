---
name: rails-docs-generator
description: Generate comprehensive documentation for Rails applications including README templates, API documentation (Swagger/OpenAPI), YARD documentation, and ADRs (Architecture Decision Records).
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - documentation
  - swagger
  - openapi
  - yard
  - adr
  - readme
dependencies:
  - rails >= 7.0
---

# Rails Documentation Generator

A comprehensive guide for generating and maintaining documentation in Ruby on Rails applications. This skill covers README templates, API documentation with Swagger/OpenAPI, YARD documentation for code, Architecture Decision Records (ADRs), and automated documentation workflows.

## Use this skill when

- Creating project README files
- Documenting REST APIs with Swagger/OpenAPI
- Generating code documentation with YARD
- Recording architecture decisions with ADRs
- Setting up automated documentation generation
- Creating developer onboarding documentation
- Documenting deployment procedures
- Creating API changelogs
- Generating database schema documentation
- Creating style guides and conventions
- Documenting background jobs and cron tasks
- Creating troubleshooting guides
- Maintaining migration guides between versions

## Do not use this skill when

- Writing inline code comments (just write clear code)
- The project doesn't need external documentation
- Documentation would be redundant with existing tools
- Time constraints prevent proper maintenance
- The API is internal-only and doesn't need public docs

## Prerequisites

- Rails 7.0+ installed
- Understanding of documentation best practices
- Familiarity with Markdown
- Basic understanding of OpenAPI specification
- Git for version control

## Core Concepts

### Documentation Types

1. **README**: Project overview, setup instructions, usage examples
2. **API Documentation**: REST API endpoints, request/response formats
3. **Code Documentation**: Inline documentation for classes and methods
4. **ADRs**: Architecture decisions and their context
5. **Guides**: How-to documents for common tasks
6. **Changelogs**: Version history and breaking changes

### Documentation Principles

- **Keep it up-to-date**: Outdated docs are worse than no docs
- **Make it discoverable**: Easy to find what you need
- **Show examples**: Code examples are worth a thousand words
- **Explain why, not just what**: Context matters
- **Version your docs**: Match docs to code versions

## Step-by-Step Implementation

### Step 1: Create Comprehensive README

#### Basic README Template

```markdown
# Project Name

> Brief description of what this project does

[![Rails Version](https://img.shields.io/badge/Rails-7.1-red.svg)](https://rubyonrails.org/)
[![Ruby Version](https://img.shields.io/badge/Ruby-3.2-red.svg)](https://www.ruby-lang.org/)
[![Build Status](https://img.shields.io/github/actions/workflow/status/username/repo/ci.yml)](https://github.com/username/repo/actions)
[![Coverage](https://img.shields.io/codecov/c/github/username/repo)](https://codecov.io/gh/username/repo)

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Features

- User authentication with JWT
- RESTful API with versioning
- Background job processing with Solid Queue
- Real-time notifications with ActionCable
- Comprehensive test coverage with RSpec
- API documentation with Swagger
- Docker support for development and production

## Prerequisites

Before you begin, ensure you have the following installed:

- Ruby 3.2 or higher
- Rails 7.1 or higher
- PostgreSQL 14 or higher
- Redis 7.0 or higher
- Node.js 18 or higher (for asset compilation)
- Docker and Docker Compose (optional)

## Installation

### Local Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/username/project-name.git
   cd project-name
   ```

2. **Install dependencies**

   ```bash
   bundle install
   npm install
   ```

3. **Setup database**

   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Set up environment variables**

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Start the server**

   ```bash
   rails server
   ```

   Visit http://localhost:3000

### Docker Setup

1. **Build and start containers**

   ```bash
   docker-compose up
   ```

2. **Setup database**

   ```bash
   docker-compose exec web rails db:setup
   ```

   Visit http://localhost:3000

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Database
DATABASE_URL=postgresql://localhost/myapp_development

# Redis
REDIS_URL=redis://localhost:6379/0

# API Keys
SECRET_KEY_BASE=your_secret_key_here
JWT_SECRET=your_jwt_secret_here
API_KEY=your_api_key_here

# External Services
SENDGRID_API_KEY=your_sendgrid_key
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name

# Feature Flags
ENABLE_REGISTRATION=true
ENABLE_NOTIFICATIONS=true
```

### Configuration Files

- `config/database.yml` - Database configuration
- `config/cable.yml` - ActionCable configuration
- `config/storage.yml` - Active Storage configuration
- `config/credentials.yml.enc` - Encrypted credentials

## Usage

### Authentication

The API uses JWT for authentication. Include the token in the Authorization header:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://api.example.com/api/v1/users
```

### API Endpoints

#### Create User

```bash
POST /api/v1/users
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "username": "johndoe"
  }
}
```

#### Response

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "username": "johndoe",
    "created_at": "2024-01-15T10:00:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

For complete API documentation, visit `/api-docs` when running the server.

## API Documentation

Interactive API documentation is available at:

- Development: http://localhost:3000/api-docs
- Production: https://api.example.com/api-docs

Documentation is generated from RSpec request specs using rswag.

To regenerate documentation:

```bash
rails rswag:specs:swaggerize
```

## Testing

### Run all tests

```bash
bundle exec rspec
```

### Run specific test file

```bash
bundle exec rspec spec/models/user_spec.rb
```

### Run with coverage report

```bash
COVERAGE=true bundle exec rspec
open coverage/index.html
```

### Linting

```bash
bundle exec rubocop
bundle exec rubocop -A  # Auto-fix issues
```

## Deployment

### Heroku

1. **Create Heroku app**

   ```bash
   heroku create your-app-name
   ```

2. **Add PostgreSQL addon**

   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

3. **Set environment variables**

   ```bash
   heroku config:set SECRET_KEY_BASE=$(rails secret)
   heroku config:set JWT_SECRET=$(rails secret)
   ```

4. **Deploy**

   ```bash
   git push heroku main
   heroku run rails db:migrate
   ```

### Docker Production

Build and push Docker image:

```bash
docker build -t your-registry/app-name:latest .
docker push your-registry/app-name:latest
```

## Project Structure

```
├── app/
│   ├── controllers/        # API controllers
│   ├── models/             # ActiveRecord models
│   ├── services/           # Business logic services
│   ├── jobs/               # Background jobs
│   ├── mailers/            # Email templates
│   └── serializers/        # JSON serializers
├── config/                 # Configuration files
├── db/
│   ├── migrate/            # Database migrations
│   └── seeds.rb            # Seed data
├── docs/                   # Additional documentation
│   ├── api/                # API documentation
│   ├── architecture/       # Architecture Decision Records
│   └── guides/             # How-to guides
├── lib/                    # Custom libraries
├── spec/                   # RSpec tests
└── swagger/                # OpenAPI specification
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and development process.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@example.com or join our Slack channel.

## Acknowledgments

- Rails community for the amazing framework
- Contributors who helped build this project
- Open source libraries that make this possible
```

### Step 2: Generate API Documentation with Swagger/OpenAPI

#### Install rswag

```ruby
# Gemfile
group :development, :test do
  gem 'rswag-specs'
end

gem 'rswag-api'
gem 'rswag-ui'
```

```bash
bundle install
rails g rswag:install
```

#### Configure Swagger

```ruby
# spec/swagger_helper.rb
require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1',
        description: 'API documentation for MyApp V1',
        contact: {
          name: 'API Support',
          email: 'api@example.com',
          url: 'https://example.com/support'
        },
        license: {
          name: 'MIT',
          url: 'https://opensource.org/licenses/MIT'
        }
      },
      servers: [
        {
          url: 'https://{environment}.example.com',
          variables: {
            environment: {
              default: 'api',
              enum: ['api', 'api-staging']
            }
          }
        },
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        }
      ],
      paths: {},
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'JWT token for authentication'
          },
          apiKey: {
            type: :apiKey,
            name: 'X-API-Key',
            in: :header,
            description: 'API key for authentication'
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              email: { type: :string, format: :email, example: 'user@example.com' },
              username: { type: :string, example: 'johndoe' },
              first_name: { type: :string, example: 'John' },
              last_name: { type: :string, example: 'Doe' },
              created_at: { type: :string, format: :datetime, example: '2024-01-15T10:00:00Z' },
              updated_at: { type: :string, format: :datetime, example: '2024-01-15T10:00:00Z' }
            },
            required: ['id', 'email', 'username']
          },
          Post: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              title: { type: :string, example: 'My First Post' },
              body: { type: :string, example: 'This is the post content' },
              published: { type: :boolean, example: true },
              user_id: { type: :integer, example: 1 },
              created_at: { type: :string, format: :datetime },
              updated_at: { type: :string, format: :datetime }
            },
            required: ['id', 'title', 'body']
          },
          Error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: { type: :string, example: 'validation_failed' },
                  message: { type: :string, example: 'Validation failed' },
                  status: { type: :integer, example: 422 },
                  details: {
                    type: :array,
                    items: {
                      type: :object,
                      properties: {
                        field: { type: :string },
                        messages: { type: :array, items: { type: :string } }
                      }
                    }
                  }
                },
                required: ['code', 'message', 'status']
              }
            }
          },
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer, example: 1 },
              next_page: { type: :integer, nullable: true, example: 2 },
              prev_page: { type: :integer, nullable: true, example: nil },
              total_pages: { type: :integer, example: 10 },
              total_count: { type: :integer, example: 200 },
              per_page: { type: :integer, example: 20 }
            }
          }
        }
      },
      tags: [
        { name: 'Users', description: 'User management endpoints' },
        { name: 'Posts', description: 'Blog post endpoints' },
        { name: 'Authentication', description: 'Authentication endpoints' }
      ]
    }
  }

  config.openapi_format = :yaml
end
```

#### Create API Spec

```ruby
# spec/requests/api/v1/users_spec.rb
require 'swagger_helper'

RSpec.describe 'api/v1/users', type: :request do
  path '/api/v1/users' do
    get('List users') do
      tags 'Users'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :page,
                in: :query,
                type: :integer,
                required: false,
                description: 'Page number for pagination',
                example: 1

      parameter name: :per_page,
                in: :query,
                type: :integer,
                required: false,
                description: 'Number of items per page',
                example: 20

      parameter name: :search,
                in: :query,
                type: :string,
                required: false,
                description: 'Search query',
                example: 'john'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/User' }
                 },
                 meta: { '$ref' => '#/components/schemas/PaginationMeta' }
               },
               required: ['data', 'meta']

        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(user) }
        let(:user) { create(:user) }
        let(:page) { 1 }
        let(:per_page) { 20 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
          expect(data['meta']).to include('current_page', 'total_pages')
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'

        run_test!
      end
    end

    post('Create user') do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :user,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    user: {
                      type: :object,
                      properties: {
                        email: { type: :string, format: :email },
                        username: { type: :string },
                        password: { type: :string, format: :password },
                        password_confirmation: { type: :string, format: :password },
                        first_name: { type: :string },
                        last_name: { type: :string }
                      },
                      required: ['email', 'username', 'password', 'password_confirmation']
                    }
                  }
                }

      response(201, 'created') do
        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/User' },
                 message: { type: :string }
               },
               required: ['data']

        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(admin) }
        let(:admin) { create(:user, :admin) }
        let(:user) do
          {
            user: {
              email: 'newuser@example.com',
              username: 'newuser',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'New',
              last_name: 'User'
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']['email']).to eq('newuser@example.com')
        end
      end

      response(422, 'unprocessable entity') do
        schema '$ref' => '#/components/schemas/Error'

        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(admin) }
        let(:admin) { create(:user, :admin) }
        let(:user) do
          {
            user: {
              email: 'invalid',
              username: '',
              password: '123',
              password_confirmation: '456'
            }
          }
        end

        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'User ID'

    get('Show user') do
      tags 'Users'
      produces 'application/json'
      security [bearerAuth: []]

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 data: { '$ref' => '#/components/schemas/User' }
               },
               required: ['data']

        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(current_user) }
        let(:current_user) { create(:user) }
        let(:id) { current_user.id }

        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'

        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(user) }
        let(:user) { create(:user) }
        let(:id) { 'invalid' }

        run_test!
      end
    end

    patch('Update user') do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :user,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    user: {
                      type: :object,
                      properties: {
                        username: { type: :string },
                        first_name: { type: :string },
                        last_name: { type: :string }
                      }
                    }
                  }
                }

      response(200, 'successful') do
        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(current_user) }
        let(:current_user) { create(:user) }
        let(:id) { current_user.id }
        let(:user) do
          {
            user: {
              username: 'updated_username'
            }
          }
        end

        run_test!
      end
    end

    delete('Delete user') do
      tags 'Users'
      produces 'application/json'
      security [bearerAuth: []]

      response(204, 'no content') do
        let(:Authorization) { "Bearer #{token}" }
        let(:token) { generate_jwt_token(admin) }
        let(:admin) { create(:user, :admin) }
        let(:user_to_delete) { create(:user) }
        let(:id) { user_to_delete.id }

        run_test!
      end
    end
  end
end
```

#### Generate Swagger Documentation

```bash
# Generate swagger.yaml from specs
SWAGGER_DRY_RUN=0 rails rswag:specs:swaggerize

# View documentation
rails server
# Visit http://localhost:3000/api-docs
```

#### Configure Swagger UI

```ruby
# config/initializers/rswag_ui.rb
Rswag::Ui.configure do |c|
  c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'API V1 Docs'

  # Custom configuration
  c.config_object[:deepLinking] = true
  c.config_object[:displayRequestDuration] = true
  c.config_object[:docExpansion] = 'none'
  c.config_object[:filter] = true
  c.config_object[:showExtensions] = true
  c.config_object[:showCommonExtensions] = true
  c.config_object[:tryItOutEnabled] = true
end
```

### Step 3: YARD Documentation

#### Install YARD

```ruby
# Gemfile
group :development do
  gem 'yard'
  gem 'yard-activerecord'
end
```

```bash
bundle install
```

#### Document Classes and Methods

```ruby
# app/services/users/create_service.rb

# Service for creating new users with validations and side effects.
#
# @example Create a user
#   result = Users::CreateService.call(params: user_params)
#   if result.success?
#     user = result.value
#   else
#     errors = result.error
#   end
#
# @example With dependencies injected
#   mailer = CustomMailer
#   result = Users::CreateService.new(mailer: mailer).call(params: user_params)
#
# @author John Doe
# @since 1.0.0
class Users::CreateService
  # Initializes the service with optional dependencies
  #
  # @param mailer [Class] The mailer class to use for sending emails
  # @param logger [Logger] The logger instance
  # @return [Users::CreateService]
  def initialize(mailer: UserMailer, logger: Rails.logger)
    @mailer = mailer
    @logger = logger
  end

  # Creates a new user with the given parameters
  #
  # @param params [Hash] The user parameters
  # @option params [String] :email The user's email address
  # @option params [String] :username The user's username
  # @option params [String] :password The user's password
  #
  # @return [Result] A result object containing the user or error
  # @raise [ArgumentError] if params is not a Hash
  #
  # @example Successful creation
  #   result = service.call(params: { email: 'user@example.com', username: 'john' })
  #   result.success? # => true
  #   result.value    # => #<User id: 1, email: "user@example.com">
  #
  # @example Failed creation
  #   result = service.call(params: { email: 'invalid' })
  #   result.failure? # => true
  #   result.error    # => "Email is invalid"
  def call(params:)
    raise ArgumentError, 'params must be a Hash' unless params.is_a?(Hash)

    user = User.new(params)

    if user.save
      send_welcome_email(user)
      log_creation(user)
      Result.success(user)
    else
      Result.failure(user.errors.full_messages.join(', '))
    end
  rescue => e
    logger.error("User creation failed: #{e.message}")
    Result.failure(e.message)
  end

  private

  # @return [Class] The mailer class
  attr_reader :mailer

  # @return [Logger] The logger instance
  attr_reader :logger

  # Sends welcome email to the newly created user
  #
  # @param user [User] The created user
  # @return [void]
  # @api private
  def send_welcome_email(user)
    mailer.welcome(user).deliver_later
  end

  # Logs user creation
  #
  # @param user [User] The created user
  # @return [void]
  # @api private
  def log_creation(user)
    logger.info("User created: #{user.email}")
  end
end
```

```ruby
# app/models/user.rb

# Represents a user in the system
#
# @!attribute [rw] email
#   @return [String] The user's email address
# @!attribute [rw] username
#   @return [String] The user's username
# @!attribute [rw] first_name
#   @return [String] The user's first name
# @!attribute [rw] last_name
#   @return [String] The user's last name
# @!attribute [r] created_at
#   @return [Time] When the user was created
# @!attribute [r] updated_at
#   @return [Time] When the user was last updated
#
# @example Create a new user
#   user = User.create(email: 'user@example.com', username: 'john')
#
# @example Find active users
#   active_users = User.active
#
# @since 1.0.0
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  # Returns active users
  #
  # @return [ActiveRecord::Relation<User>]
  scope :active, -> { where(status: 'active') }

  # Returns users created in the given time range
  #
  # @param start_date [Time, Date] The start date
  # @param end_date [Time, Date] The end date
  # @return [ActiveRecord::Relation<User>]
  scope :created_between, ->(start_date, end_date) {
    where(created_at: start_date..end_date)
  }

  # Returns the user's full name
  #
  # @return [String] The full name
  # @return [String] The username if name is not set
  #
  # @example
  #   user = User.new(first_name: 'John', last_name: 'Doe')
  #   user.full_name # => "John Doe"
  def full_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      username
    end
  end

  # Checks if the user is active
  #
  # @return [Boolean] true if user is active
  def active?
    status == 'active'
  end

  # Activates the user account
  #
  # @return [Boolean] true if activation was successful
  def activate!
    update(status: 'active', activated_at: Time.current)
  end

  # Deactivates the user account
  #
  # @param reason [String] The reason for deactivation
  # @return [Boolean] true if deactivation was successful
  def deactivate!(reason: nil)
    update(status: 'inactive', deactivation_reason: reason)
  end
end
```

#### Generate YARD Documentation

```bash
# Generate documentation
yard doc

# View documentation locally
yard server

# Visit http://localhost:8808
```

#### Configure YARD

```ruby
# .yardopts
--markup markdown
--no-private
--protected
--output-dir doc/yard
--readme README.md
app/**/*.rb
lib/**/*.rb
```

```yaml
# .yardoc_options
:markup: markdown
:markup_provider: redcarpet
:hide_void_return: true
:embed_mixins: true
:show_hash: true
:list_exclude:
  - spec/**/*
  - test/**/*
```

### Step 4: Architecture Decision Records (ADRs)

#### ADR Template

```markdown
# docs/architecture/decisions/0001-use-postgresql-for-database.md

# 1. Use PostgreSQL as Primary Database

Date: 2024-01-15

## Status

Accepted

## Context

We need to choose a database system for our Rails application. The application requires:
- Complex queries with joins
- Full-text search capabilities
- JSON data storage for flexible schemas
- ACID compliance for financial transactions
- High performance with large datasets
- Support for geospatial queries (future requirement)

Options considered:
1. PostgreSQL
2. MySQL
3. MongoDB

## Decision

We will use PostgreSQL as our primary database.

## Rationale

PostgreSQL provides:
- **Advanced features**: JSON/JSONB support, full-text search, array types, window functions
- **Performance**: Excellent query optimizer, efficient indexing including GiST and GIN
- **Reliability**: ACID compliant, proven in production at scale
- **Geospatial support**: PostGIS extension for location-based features
- **Rails integration**: First-class support in Rails, mature ActiveRecord adapter
- **Community**: Large ecosystem, extensive documentation, active development
- **Cost**: Open source with no licensing fees

## Consequences

### Positive

- Rich feature set reduces need for external services (e.g., Elasticsearch for search)
- JSON support allows schema flexibility where needed
- Strong consistency guarantees for financial data
- Geospatial capabilities future-proof location features
- Well-known technology reduces hiring/training costs

### Negative

- Slightly more complex to set up than MySQL
- Requires PostgreSQL-specific knowledge for advanced features
- Migration from other databases requires schema adjustments
- Hosting options may be more limited/expensive than MySQL

### Neutral

- Need to use PostgreSQL-specific extensions (requires `structure.sql` instead of `schema.rb`)
- Team needs to learn PostgreSQL-specific SQL syntax
- Development environment needs PostgreSQL installed

## Implementation

1. Install PostgreSQL 14+
2. Configure Rails to use PostgreSQL adapter
3. Use `structure.sql` for schema management
4. Enable required extensions in migrations:
   - `pgcrypto` for UUID generation
   - `pg_trgm` for full-text search
5. Set up database connection pooling with PgBouncer for production

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Rails PostgreSQL Guide](https://guides.rubyonrails.org/configuring.html#configuring-a-postgresql-database)
- [PostgreSQL vs MySQL Comparison](https://example.com/comparison)

## Notes

- Review decision in 12 months
- Monitor query performance metrics
- Consider read replicas if read load increases
```

#### More ADR Examples

```markdown
# docs/architecture/decisions/0002-use-solid-queue-for-background-jobs.md

# 2. Use Solid Queue for Background Jobs

Date: 2024-01-20

## Status

Accepted

Supersedes: ADR 0000 (Use Sidekiq)

## Context

Rails 8 introduced Solid Queue as a native background job solution. We need to decide whether to:
1. Continue using Sidekiq (current solution)
2. Migrate to Solid Queue
3. Use alternative solutions (GoodJob, Delayed::Job)

Key requirements:
- Reliable job processing
- Job scheduling capabilities
- Monitoring and observability
- Low operational overhead
- Cost efficiency

## Decision

We will migrate from Sidekiq to Solid Queue.

## Rationale

Solid Queue advantages:
- **Native Rails integration**: Built specifically for Rails 8+
- **Database-backed**: Uses PostgreSQL, eliminating Redis dependency
- **Simplicity**: Fewer moving parts, easier operations
- **Cost savings**: No Redis hosting costs
- **ACID guarantees**: Database transactions ensure job reliability
- **Built-in features**: Scheduling, priorities, retries out of the box

## Consequences

### Positive

- Simplified infrastructure (one less service)
- Reduced costs (no Redis for jobs)
- Improved reliability through database transactions
- Better Rails integration
- Easier local development setup

### Negative

- Migration effort from Sidekiq
- Potential performance impact (database vs Redis)
- Less mature ecosystem
- Need to retrain team

## Implementation

1. Add `solid_queue` gem
2. Run solid_queue install generator
3. Create migration plan for existing jobs
4. Update deployment configuration
5. Monitor performance metrics

## References

- [Solid Queue GitHub](https://github.com/basecamp/solid_queue)
- [Rails 8 Release Notes](https://edgeguides.rubyonrails.org/8_0_release_notes.html)

## Notes

- Review performance after 3 months
- Keep Sidekiq adapter code for potential rollback
```

#### ADR Index

```markdown
# docs/architecture/decisions/README.md

# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for significant architectural decisions made in this project.

## What is an ADR?

An ADR is a document that captures an important architectural decision made along with its context and consequences.

## Format

Each ADR follows this structure:
- **Title**: Short descriptive name
- **Status**: Proposed, Accepted, Deprecated, Superseded
- **Context**: The issue motivating this decision
- **Decision**: The change we're proposing
- **Rationale**: Why this decision was made
- **Consequences**: Positive, negative, and neutral outcomes

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](./0001-use-postgresql-for-database.md) | Use PostgreSQL as Primary Database | Accepted | 2024-01-15 |
| [0002](./0002-use-solid-queue-for-background-jobs.md) | Use Solid Queue for Background Jobs | Accepted | 2024-01-20 |
| [0003](./0003-api-versioning-strategy.md) | URL-based API Versioning | Accepted | 2024-02-01 |
| [0004](./0004-authentication-strategy.md) | JWT Authentication for API | Accepted | 2024-02-05 |
| [0005](./0005-file-storage-strategy.md) | Use AWS S3 for File Storage | Accepted | 2024-02-10 |

## Creating a New ADR

1. Copy `template.md` to a new file
2. Use sequential numbering (e.g., `0006-title.md`)
3. Fill in all sections
4. Update this index
5. Submit for review via pull request
```

### Step 5: Changelog

```markdown
# CHANGELOG.md

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature coming in next release

### Changed
- Improvements to existing features

### Fixed
- Bug fixes

## [2.0.0] - 2024-02-01

### Added
- API v2 with improved response format
- Rate limiting for API endpoints
- Webhook support for event notifications
- User avatar upload functionality
- Admin dashboard for user management

### Changed
- **BREAKING**: API v1 response format updated
- **BREAKING**: Authentication now requires JWT tokens
- Improved error messages with detailed validation feedback
- Updated Ruby to 3.2.0
- Updated Rails to 7.1.0
- Database queries optimized for better performance

### Deprecated
- API v1 endpoints (will be removed in 3.0.0)
- Basic auth support (use JWT instead)

### Removed
- Legacy password reset flow
- Deprecated API endpoints from v0.x

### Fixed
- User registration email verification bug
- Race condition in subscription creation
- Memory leak in background jobs
- Timezone handling in scheduled tasks

### Security
- Fixed SQL injection vulnerability in search
- Updated dependencies with security patches
- Added rate limiting to prevent brute force attacks

## [1.5.0] - 2024-01-15

### Added
- Full-text search for posts
- Export data to CSV functionality
- Email notification preferences

### Changed
- Improved pagination performance
- Updated UI components

### Fixed
- Post creation validation errors
- Email delivery issues

## [1.0.0] - 2023-12-01

### Added
- Initial release
- User authentication with JWT
- RESTful API for users and posts
- Background job processing
- Email notifications
- API documentation with Swagger

[Unreleased]: https://github.com/username/project/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/username/project/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/username/project/compare/v1.0.0...v1.5.0
[1.0.0]: https://github.com/username/project/releases/tag/v1.0.0
```

### Step 6: API Changelog

```markdown
# docs/api/CHANGELOG.md

# API Changelog

## API v2 (Current)

### 2024-02-01 - v2.0.0

**Breaking Changes:**
- Response format now wraps data in `data` key
- Error format standardized across all endpoints
- Authentication requires JWT (Bearer token)
- Pagination metadata moved to `meta` key

**New Endpoints:**
- `POST /api/v2/webhooks` - Register webhook subscriptions
- `GET /api/v2/users/:id/activity` - Get user activity feed
- `POST /api/v2/users/bulk` - Bulk user operations

**Updated Endpoints:**
- `GET /api/v2/users`
  - Added `search` query parameter
  - Added `sort_by` and `sort_order` parameters
  - Response now includes pagination links

**Deprecated:**
- None

**Migration Guide:**

```javascript
// Old (v1)
{
  "users": [...],
  "page": 1,
  "total": 100
}

// New (v2)
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 100
  },
  "links": {
    "first": "...",
    "prev": null,
    "self": "...",
    "next": "...",
    "last": "..."
  }
}
```

## API v1 (Deprecated)

### 2024-01-15 - v1.5.0

**Deprecation Notice:**
API v1 will be sunset on 2024-06-01. Please migrate to v2.

**Last Updates:**
- Security patches applied
- Bug fixes only
- No new features
```

## Best Practices

### 1. Keep Documentation Close to Code

```ruby
# Good: Documentation in the code
class User < ApplicationRecord
  # Returns active users
  # @return [ActiveRecord::Relation<User>]
  scope :active, -> { where(status: 'active') }
end

# Good: Tests as documentation
RSpec.describe User do
  describe '.active' do
    it 'returns only active users' do
      active_user = create(:user, status: 'active')
      inactive_user = create(:user, status: 'inactive')

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end
end
```

### 2. Automate Documentation Generation

```ruby
# lib/tasks/docs.rake
namespace :docs do
  desc 'Generate all documentation'
  task all: :environment do
    Rake::Task['docs:api'].invoke
    Rake::Task['docs:yard'].invoke
    Rake::Task['docs:erd'].invoke
  end

  desc 'Generate API documentation'
  task api: :environment do
    puts 'Generating API documentation...'
    system('SWAGGER_DRY_RUN=0 rails rswag:specs:swaggerize')
    puts 'API documentation generated!'
  end

  desc 'Generate code documentation'
  task yard: :environment do
    puts 'Generating YARD documentation...'
    system('yard doc')
    puts 'YARD documentation generated!'
  end

  desc 'Generate entity relationship diagram'
  task erd: :environment do
    puts 'Generating ERD...'
    system('bundle exec erd --filename=docs/erd')
    puts 'ERD generated!'
  end
end
```

### 3. Version Your Documentation

```bash
# docs/api/v1/
# docs/api/v2/
# swagger/v1/swagger.yaml
# swagger/v2/swagger.yaml
```

### 4. Include Examples

Always include working examples:

```markdown
## Creating a User

### Request

```bash
curl -X POST https://api.example.com/api/v1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "user": {
      "email": "john@example.com",
      "username": "johndoe",
      "password": "securepassword123"
    }
  }'
```

### Response

```json
{
  "data": {
    "id": 123,
    "email": "john@example.com",
    "username": "johndoe",
    "created_at": "2024-01-15T10:00:00Z"
  },
  "message": "User created successfully"
}
```
```

### 5. Document Error Responses

```markdown
## Error Responses

All error responses follow this format:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed",
    "status": 422,
    "details": [
      {
        "field": "email",
        "messages": ["has already been taken"],
        "codes": ["taken"]
      }
    ]
  }
}
```

### Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `bad_request` | 400 | Malformed request |
| `unauthorized` | 401 | Invalid or missing authentication |
| `forbidden` | 403 | Not authorized to perform action |
| `not_found` | 404 | Resource not found |
| `validation_failed` | 422 | Validation errors |
| `too_many_requests` | 429 | Rate limit exceeded |
| `internal_server_error` | 500 | Server error |
```

## Common Mistakes

### 1. Outdated Documentation

```ruby
# Bad: Comment doesn't match code
# Returns all users
def active_users
  User.where(status: 'active')
end

# Good: Accurate documentation
# Returns all active users
def active_users
  User.where(status: 'active')
end
```

### 2. Missing Examples

```markdown
<!-- Bad: No examples -->
## POST /api/v1/users
Creates a user.

<!-- Good: With examples -->
## POST /api/v1/users

Creates a new user account.

**Example Request:**
...
```

### 3. No Versioning

```markdown
<!-- Bad: Changing docs without versioning -->
# API Documentation
...

<!-- Good: Versioned docs -->
# API Documentation v2
Changes from v1:
- New response format
- Additional fields
...
```

### 4. Poor Organization

```
# Bad structure
docs/
  file1.md
  file2.md
  notes.txt
  old_stuff.md

# Good structure
docs/
  README.md
  api/
    v1/
    v2/
  architecture/
    decisions/
    diagrams/
  guides/
    deployment.md
    development.md
```

## Conclusion

Good documentation is essential for:
- Developer onboarding
- API consumers
- Future maintenance
- Knowledge sharing
- Debugging and troubleshooting

Remember:
- Keep docs up-to-date
- Use automation where possible
- Include examples
- Version your documentation
- Make it easy to find and read
