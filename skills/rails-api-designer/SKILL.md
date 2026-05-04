---
name: rails-api-designer
description: REST API design patterns, versioning, serialization, pagination, error handling for Rails applications
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - api
  - rest
  - json
  - serialization
  - versioning
  - pagination
dependencies:
  - rails >= 7.0
---

# Rails API Designer

A comprehensive guide for designing, building, and maintaining production-grade REST APIs in Rails applications. This skill covers API versioning strategies, serialization patterns, pagination approaches, error handling, authentication, rate limiting, and API documentation.

## Use this skill when

- Designing a new REST API for a Rails application
- Adding API versioning to an existing application
- Implementing serialization for complex models
- Setting up pagination for large datasets
- Designing comprehensive error handling for APIs
- Adding rate limiting and throttling
- Implementing API authentication (token-based, JWT, OAuth)
- Creating API documentation (OpenAPI/Swagger)
- Migrating from GraphQL to REST or vice versa
- Optimizing API response times and payload sizes
- Implementing HATEOAS or HAL-style hypermedia APIs
- Setting up API monitoring and analytics
- Designing webhook systems
- Creating public or partner APIs
- Implementing API deprecation strategies

## Do not use this skill when

- Building server-rendered HTML views (use standard Rails views)
- Creating simple internal tools without external API consumers
- Working with GraphQL APIs (use a GraphQL-specific skill)
- Implementing real-time features (consider WebSockets/ActionCable)
- Building gRPC services (different protocol requirements)
- Working with legacy SOAP APIs (different architecture)
- The application doesn't need programmatic access

## Prerequisites

- Rails 7.0+ installed
- Understanding of REST principles and HTTP methods
- Familiarity with JSON data structures
- Basic understanding of API authentication
- Knowledge of database query optimization

## Core Concepts

### REST Principles

REST (Representational State Transfer) is an architectural style that defines a set of constraints for creating web services:

1. **Client-Server Architecture**: Separation of concerns between UI and data storage
2. **Stateless**: Each request contains all information needed to process it
3. **Cacheable**: Responses must define themselves as cacheable or not
4. **Uniform Interface**: Consistent resource identification and manipulation
5. **Layered System**: Client doesn't know if connected directly to end server
6. **Code on Demand** (optional): Server can extend client functionality

### Resource-Oriented Design

APIs should be designed around resources (nouns) rather than actions (verbs):

```
Good:
GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

Bad:
POST   /api/v1/createUser
POST   /api/v1/getUser
POST   /api/v1/updateUser
POST   /api/v1/deleteUser
```

### HTTP Verbs and Idempotency

- **GET**: Retrieve resources (idempotent, safe, cacheable)
- **POST**: Create new resources (not idempotent)
- **PUT**: Replace entire resource (idempotent)
- **PATCH**: Partial update (idempotent)
- **DELETE**: Remove resource (idempotent)
- **HEAD**: Same as GET but without response body
- **OPTIONS**: Describe communication options

## Step-by-Step Implementation

### Step 1: Configure Rails for API-Only Mode

#### Option A: New API-Only Application

```bash
rails new myapp --api --database=postgresql
```

This generates a streamlined application without:
- Views, helpers, and assets
- Session middleware
- CSRF protection
- Cookie support (unless explicitly enabled)

#### Option B: Add API to Existing Application

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.1

    # API-specific middleware
    config.api_only = false # Keep false if you need views too

    # Add CORS support
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # Configure appropriately for production
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: false
      end
    end
  end
end
```

```ruby
# Gemfile
gem 'rack-cors'
gem 'jbuilder'      # For JSON view templates
gem 'blueprinter'   # Alternative serializer (recommended)
gem 'pagy'          # Pagination
gem 'oj'            # Fast JSON parsing
```

#### Configure API Controllers

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods
    include Pagy::Backend

    # Add back specific modules as needed
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection

    # Exception handling
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from Pundit::NotAuthorizedError, with: :forbidden

    before_action :authenticate_request
    before_action :set_default_format

    private

    def set_default_format
      request.format = :json unless params[:format]
    end

    def authenticate_request
      authenticate_with_http_token do |token, options|
        @current_user = User.find_by(api_token: token)
      end

      render_unauthorized unless @current_user
    end

    def current_user
      @current_user
    end

    def render_unauthorized
      render json: {
        error: {
          code: 'unauthorized',
          message: 'Invalid or missing authentication token',
          status: 401
        }
      }, status: :unauthorized
    end

    def not_found(exception)
      render json: {
        error: {
          code: 'not_found',
          message: exception.message,
          status: 404
        }
      }, status: :not_found
    end

    def unprocessable_entity(exception)
      render json: {
        error: {
          code: 'validation_failed',
          message: 'Validation failed',
          status: 422,
          details: exception.record.errors.as_json
        }
      }, status: :unprocessable_entity
    end

    def bad_request(exception)
      render json: {
        error: {
          code: 'bad_request',
          message: exception.message,
          status: 400
        }
      }, status: :bad_request
    end

    def forbidden(exception)
      render json: {
        error: {
          code: 'forbidden',
          message: 'You are not authorized to perform this action',
          status: 403
        }
      }, status: :forbidden
    end
  end
end
```

### Step 2: Implement API Versioning

#### URL-Based Versioning (Recommended)

Most explicit and widely used approach:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users do
        resources :posts
      end
      resources :comments
    end

    namespace :v2 do
      resources :users do
        resources :posts
        resources :followers
      end
    end
  end
end
```

Directory structure:
```
app/controllers/
  api/
    base_controller.rb
    v1/
      base_controller.rb
      users_controller.rb
      posts_controller.rb
      comments_controller.rb
    v2/
      base_controller.rb
      users_controller.rb
      posts_controller.rb
      followers_controller.rb
```

#### Version-Specific Base Controllers

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < Api::BaseController
      # V1-specific configurations
      def api_version
        'v1'
      end
    end
  end
end
```

```ruby
# app/controllers/api/v2/base_controller.rb
module Api
  module V2
    class BaseController < Api::BaseController
      # V2-specific configurations
      def api_version
        'v2'
      end

      # Override default pagination if needed
      def default_per_page
        50 # V2 returns more items per page
      end
    end
  end
end
```

#### Header-Based Versioning (Alternative)

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    scope module: :v1, constraints: ApiVersionConstraint.new(version: 1, default: true) do
      resources :users
    end

    scope module: :v2, constraints: ApiVersionConstraint.new(version: 2) do
      resources :users
    end
  end
end
```

```ruby
# lib/api_version_constraint.rb
class ApiVersionConstraint
  def initialize(version:, default: false)
    @version = version
    @default = default
  end

  def matches?(request)
    @default || request.headers['Accept']&.include?("application/vnd.myapp.v#{@version}+json")
  end
end
```

#### Content Negotiation Versioning

```ruby
# Client sends:
# Accept: application/vnd.myapp.v2+json

# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    before_action :validate_api_version

    private

    def validate_api_version
      version = extract_version_from_accept_header
      unless ['v1', 'v2'].include?(version)
        render json: { error: 'Unsupported API version' }, status: :not_acceptable
      end
    end

    def extract_version_from_accept_header
      accept = request.headers['Accept']
      return 'v1' unless accept # Default version

      match = accept.match(/application\/vnd\.myapp\.(?<version>v\d+)\+json/)
      match ? match[:version] : 'v1'
    end
  end
end
```

### Step 3: Design Resource Controllers

#### Basic CRUD Controller

```ruby
# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [:show, :update, :destroy]
      skip_before_action :authenticate_request, only: [:index, :show]

      # GET /api/v1/users
      def index
        @pagy, @users = pagy(User.includes(:profile).order(created_at: :desc))

        render json: {
          data: UserBlueprint.render_as_hash(@users),
          meta: pagination_meta(@pagy)
        }
      end

      # GET /api/v1/users/:id
      def show
        render json: {
          data: UserBlueprint.render_as_hash(@user, view: :detailed)
        }
      end

      # POST /api/v1/users
      def create
        @user = User.new(user_params)

        if @user.save
          render json: {
            data: UserBlueprint.render_as_hash(@user),
            message: 'User created successfully'
          }, status: :created, location: api_v1_user_url(@user)
        else
          render json: {
            error: {
              code: 'validation_failed',
              message: 'User could not be created',
              details: @user.errors.as_json
            }
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/users/:id
      def update
        if @user.update(user_params)
          render json: {
            data: UserBlueprint.render_as_hash(@user),
            message: 'User updated successfully'
          }
        else
          render json: {
            error: {
              code: 'validation_failed',
              message: 'User could not be updated',
              details: @user.errors.as_json
            }
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        @user.destroy
        head :no_content
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :email,
          :username,
          :first_name,
          :last_name,
          :bio,
          profile_attributes: [:avatar, :website, :location]
        )
      end

      def pagination_meta(pagy)
        {
          current_page: pagy.page,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.items,
          next_page: pagy.next,
          prev_page: pagy.prev
        }
      end
    end
  end
end
```

#### Nested Resources Controller

```ruby
# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < BaseController
      before_action :set_user
      before_action :set_post, only: [:show, :update, :destroy]

      # GET /api/v1/users/:user_id/posts
      def index
        @pagy, @posts = pagy(@user.posts.includes(:comments).order(created_at: :desc))

        render json: {
          data: PostBlueprint.render_as_hash(@posts),
          meta: pagination_meta(@pagy)
        }
      end

      # GET /api/v1/users/:user_id/posts/:id
      def show
        render json: {
          data: PostBlueprint.render_as_hash(@post, view: :detailed)
        }
      end

      # POST /api/v1/users/:user_id/posts
      def create
        @post = @user.posts.build(post_params)

        if @post.save
          render json: {
            data: PostBlueprint.render_as_hash(@post),
            message: 'Post created successfully'
          }, status: :created, location: api_v1_user_post_url(@user, @post)
        else
          render json: {
            error: {
              code: 'validation_failed',
              message: 'Post could not be created',
              details: @post.errors.as_json
            }
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/users/:user_id/posts/:id
      def update
        authorize @post # Using Pundit

        if @post.update(post_params)
          render json: {
            data: PostBlueprint.render_as_hash(@post),
            message: 'Post updated successfully'
          }
        else
          render json: {
            error: {
              code: 'validation_failed',
              message: 'Post could not be updated',
              details: @post.errors.as_json
            }
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:user_id/posts/:id
      def destroy
        authorize @post

        @post.destroy
        head :no_content
      end

      private

      def set_user
        @user = User.find(params[:user_id])
      end

      def set_post
        @post = @user.posts.find(params[:id])
      end

      def post_params
        params.require(:post).permit(:title, :body, :published, tag_ids: [])
      end
    end
  end
end
```

#### Custom Actions Beyond CRUD

```ruby
# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/users/:id/followers
      def followers
        @user = User.find(params[:id])
        @pagy, @followers = pagy(@user.followers)

        render json: {
          data: UserBlueprint.render_as_hash(@followers, view: :simple),
          meta: pagination_meta(@pagy)
        }
      end

      # POST /api/v1/users/:id/follow
      def follow
        @user = User.find(params[:id])

        if current_user.follow(@user)
          render json: {
            data: {
              following: true,
              follower_count: @user.followers.count
            },
            message: "You are now following #{@user.username}"
          }
        else
          render json: {
            error: {
              code: 'action_failed',
              message: 'Could not follow user'
            }
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id/unfollow
      def unfollow
        @user = User.find(params[:id])

        if current_user.unfollow(@user)
          render json: {
            data: {
              following: false,
              follower_count: @user.followers.count
            },
            message: "You unfollowed #{@user.username}"
          }
        else
          render json: {
            error: {
              code: 'action_failed',
              message: 'Could not unfollow user'
            }
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/users/search
      def search
        query = params[:q]

        if query.blank?
          return render json: {
            error: {
              code: 'bad_request',
              message: 'Search query is required'
            }
          }, status: :bad_request
        end

        @pagy, @users = pagy(
          User.search(query).order(relevance: :desc),
          items: params[:per_page] || 20
        )

        render json: {
          data: UserBlueprint.render_as_hash(@users),
          meta: pagination_meta(@pagy).merge(query: query)
        }
      end
    end
  end
end
```

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :users do
      member do
        get :followers
        post :follow
        delete :unfollow
      end

      collection do
        post :search
      end
    end
  end
end
```

### Step 4: Implement Serialization

#### Using Blueprinter (Recommended)

Blueprinter is a fast, declarative serialization library.

```ruby
# Gemfile
gem 'blueprinter'
gem 'oj' # Fast JSON parsing
```

```ruby
# config/initializers/blueprinter.rb
require 'oj'

Blueprinter.configure do |config|
  config.generator = Oj
  config.sort_fields_by = :definition
  config.datetime_format = ->(datetime) { datetime.iso8601 }
end
```

```ruby
# app/blueprints/application_blueprint.rb
class ApplicationBlueprint < Blueprinter::Base
  # Global settings
  identifier :id

  # Helper method for all blueprints
  def self.render_as_json(object, options = {})
    JSON.parse(render(object, options))
  end

  def self.render_as_hash(object, options = {})
    JSON.parse(render(object, options), symbolize_names: true)
  end
end
```

```ruby
# app/blueprints/user_blueprint.rb
class UserBlueprint < ApplicationBlueprint
  # Default view
  fields :username, :email, :created_at

  # Simple view (for lists)
  view :simple do
    fields :username, :avatar_url
  end

  # Detailed view (for show action)
  view :detailed do
    fields :username, :email, :first_name, :last_name, :bio, :created_at, :updated_at

    association :profile, blueprint: ProfileBlueprint

    field :follower_count do |user|
      user.followers.count
    end

    field :following_count do |user|
      user.following.count
    end

    field :posts_count do |user|
      user.posts.count
    end
  end

  # With posts
  view :with_posts do
    include_view :detailed
    association :posts, blueprint: PostBlueprint
  end

  # Computed fields
  field :avatar_url do |user, options|
    if user.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false)
    else
      "https://ui-avatars.com/api/?name=#{user.username}"
    end
  end

  field :full_name do |user|
    "#{user.first_name} #{user.last_name}".strip.presence || user.username
  end

  # Conditional fields
  field :email, if: ->(field_name, user, options) {
    options[:current_user]&.id == user.id || options[:current_user]&.admin?
  }

  # Transform existing fields
  transform :username do |value|
    "@#{value}"
  end
end
```

```ruby
# app/blueprints/post_blueprint.rb
class PostBlueprint < ApplicationBlueprint
  fields :title, :body, :published, :created_at, :updated_at

  association :author, blueprint: UserBlueprint, view: :simple
  association :tags, blueprint: TagBlueprint

  view :simple do
    fields :id, :title, :created_at
    association :author, blueprint: UserBlueprint, view: :simple
  end

  view :detailed do
    include_view :default
    association :comments, blueprint: CommentBlueprint
    field :comments_count
  end

  field :comments_count do |post|
    post.comments.count
  end

  field :excerpt do |post|
    post.body.truncate(200)
  end

  field :reading_time do |post|
    words = post.body.split.size
    (words / 200.0).ceil # Assuming 200 words per minute
  end

  field :url do |post|
    Rails.application.routes.url_helpers.api_v1_user_post_url(
      post.user_id,
      post.id
    )
  end
end
```

```ruby
# app/blueprints/profile_blueprint.rb
class ProfileBlueprint < ApplicationBlueprint
  fields :avatar, :website, :location, :bio

  field :avatar do |profile|
    if profile.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(profile.avatar, only_path: false)
    end
  end

  field :social_links do |profile|
    {
      twitter: profile.twitter_url,
      linkedin: profile.linkedin_url,
      github: profile.github_url
    }.compact
  end
end
```

#### Using JBuilder (Alternative)

```ruby
# app/views/api/v1/users/index.json.jbuilder
json.data @users do |user|
  json.id user.id
  json.username user.username
  json.email user.email
  json.created_at user.created_at

  json.profile do
    json.partial! 'api/v1/profiles/profile', profile: user.profile
  end
end

json.meta do
  json.current_page @pagy.page
  json.total_pages @pagy.pages
  json.total_count @pagy.count
  json.per_page @pagy.items
end
```

```ruby
# app/views/api/v1/users/show.json.jbuilder
json.data do
  json.id @user.id
  json.username @user.username
  json.email @user.email
  json.first_name @user.first_name
  json.last_name @user.last_name
  json.bio @user.bio
  json.created_at @user.created_at
  json.updated_at @user.updated_at

  json.profile do
    json.partial! 'api/v1/profiles/profile', profile: @user.profile
  end

  json.posts @user.posts do |post|
    json.partial! 'api/v1/posts/post', post: post
  end

  json.follower_count @user.followers.count
  json.following_count @user.following.count
end
```

#### Using ActiveModel::Serializers (Legacy)

```ruby
# Gemfile
gem 'active_model_serializers', '~> 0.10.0'
```

```ruby
# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :created_at, :avatar_url

  has_one :profile
  has_many :posts

  def avatar_url
    if object.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.avatar, only_path: false)
    else
      "https://ui-avatars.com/api/?name=#{object.username}"
    end
  end
end
```

### Step 5: Implement Pagination

#### Using Pagy (Recommended)

Pagy is the fastest pagination gem with minimal memory footprint.

```ruby
# Gemfile
gem 'pagy'
```

```ruby
# config/initializers/pagy.rb
require 'pagy/extras/headers'
require 'pagy/extras/metadata'
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:overflow] = :last_page # Redirect to last page if beyond range
Pagy::DEFAULT[:metadata] = [:page, :items, :count, :pages, :last, :prev, :next]
```

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    include Pagy::Backend

    private

    def pagination_meta(pagy)
      {
        current_page: pagy.page,
        next_page: pagy.next,
        prev_page: pagy.prev,
        total_pages: pagy.pages,
        total_count: pagy.count,
        per_page: pagy.items
      }
    end

    def pagination_links(pagy)
      {
        first: url_for(page: 1),
        prev: pagy.prev ? url_for(page: pagy.prev) : nil,
        self: url_for(page: pagy.page),
        next: pagy.next ? url_for(page: pagy.next) : nil,
        last: url_for(page: pagy.pages)
      }.compact
    end
  end
end
```

```ruby
# app/controllers/api/v1/users_controller.rb
def index
  @pagy, @users = pagy(
    User.includes(:profile).order(created_at: :desc),
    items: params[:per_page] || 20,
    page: params[:page] || 1
  )

  render json: {
    data: UserBlueprint.render_as_hash(@users),
    meta: pagination_meta(@pagy),
    links: pagination_links(@pagy)
  }
end
```

#### Pagination Response Format

```json
{
  "data": [
    {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com"
    }
  ],
  "meta": {
    "current_page": 2,
    "next_page": 3,
    "prev_page": 1,
    "total_pages": 10,
    "total_count": 200,
    "per_page": 20
  },
  "links": {
    "first": "https://api.example.com/v1/users?page=1",
    "prev": "https://api.example.com/v1/users?page=1",
    "self": "https://api.example.com/v1/users?page=2",
    "next": "https://api.example.com/v1/users?page=3",
    "last": "https://api.example.com/v1/users?page=10"
  }
}
```

#### Cursor-Based Pagination (For Large Datasets)

```ruby
# app/controllers/api/v1/posts_controller.rb
def index
  posts_query = Post.order(created_at: :desc, id: :desc)

  if params[:cursor].present?
    cursor = decode_cursor(params[:cursor])
    posts_query = posts_query.where(
      '(created_at, id) < (?, ?)',
      cursor[:created_at],
      cursor[:id]
    )
  end

  @posts = posts_query.limit(params[:per_page] || 20)

  next_cursor = if @posts.size == (params[:per_page] || 20)
    encode_cursor(
      created_at: @posts.last.created_at,
      id: @posts.last.id
    )
  end

  render json: {
    data: PostBlueprint.render_as_hash(@posts),
    meta: {
      next_cursor: next_cursor,
      per_page: params[:per_page] || 20
    }
  }
end

private

def encode_cursor(created_at:, id:)
  Base64.urlsafe_encode64("#{created_at.to_i}:#{id}")
end

def decode_cursor(cursor)
  timestamp, id = Base64.urlsafe_decode64(cursor).split(':')
  {
    created_at: Time.zone.at(timestamp.to_i),
    id: id.to_i
  }
end
```

#### Link Header Pagination (GitHub Style)

```ruby
# app/controllers/api/base_controller.rb
after_action :set_pagination_headers, only: [:index]

private

def set_pagination_headers
  return unless @pagy

  links = []
  links << %(<#{url_for(page: 1)}>; rel="first")
  links << %(<#{url_for(page: @pagy.prev)}>; rel="prev") if @pagy.prev
  links << %(<#{url_for(page: @pagy.next)}>; rel="next") if @pagy.next
  links << %(<#{url_for(page: @pagy.pages)}>; rel="last")

  response.headers['Link'] = links.join(', ')
  response.headers['X-Total-Count'] = @pagy.count.to_s
  response.headers['X-Total-Pages'] = @pagy.pages.to_s
  response.headers['X-Page'] = @pagy.page.to_s
  response.headers['X-Per-Page'] = @pagy.items.to_s
end
```

### Step 6: Implement Error Handling

#### Standardized Error Format

```ruby
# app/models/api_error.rb
class ApiError
  attr_reader :code, :message, :status, :details

  def initialize(code:, message:, status:, details: nil)
    @code = code
    @message = message
    @status = status
    @details = details
  end

  def as_json(options = {})
    {
      error: {
        code: code,
        message: message,
        status: status,
        details: details
      }.compact
    }
  end
end
```

```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from Pundit::NotAuthorizedError, with: :handle_forbidden
    rescue_from ActionController::UnknownFormat, with: :handle_unknown_format
  end

  private

  def handle_standard_error(exception)
    log_error(exception)

    error = ApiError.new(
      code: 'internal_server_error',
      message: Rails.env.production? ? 'An unexpected error occurred' : exception.message,
      status: 500
    )

    render json: error.as_json, status: :internal_server_error
  end

  def handle_not_found(exception)
    error = ApiError.new(
      code: 'not_found',
      message: exception.message,
      status: 404
    )

    render json: error.as_json, status: :not_found
  end

  def handle_validation_error(exception)
    error = ApiError.new(
      code: 'validation_failed',
      message: 'Validation failed',
      status: 422,
      details: format_validation_errors(exception.record.errors)
    )

    render json: error.as_json, status: :unprocessable_entity
  end

  def handle_parameter_missing(exception)
    error = ApiError.new(
      code: 'bad_request',
      message: "Required parameter missing: #{exception.param}",
      status: 400
    )

    render json: error.as_json, status: :bad_request
  end

  def handle_forbidden(exception)
    error = ApiError.new(
      code: 'forbidden',
      message: 'You are not authorized to perform this action',
      status: 403
    )

    render json: error.as_json, status: :forbidden
  end

  def handle_unknown_format(exception)
    error = ApiError.new(
      code: 'not_acceptable',
      message: 'Unsupported media type. Please use application/json',
      status: 406
    )

    render json: error.as_json, status: :not_acceptable
  end

  def format_validation_errors(errors)
    errors.messages.map do |field, messages|
      {
        field: field,
        messages: messages,
        codes: errors.details[field].map { |d| d[:error] }
      }
    end
  end

  def log_error(exception)
    Rails.logger.error("API Error: #{exception.class}")
    Rails.logger.error("Message: #{exception.message}")
    Rails.logger.error("Backtrace:\n#{exception.backtrace.join("\n")}")
  end
end
```

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    include ErrorHandler

    # ... rest of the controller
  end
end
```

#### Custom Exception Classes

```ruby
# app/errors/api_errors.rb
module ApiErrors
  class BaseError < StandardError
    attr_reader :status, :code, :details

    def initialize(message = nil, status: 500, code: 'error', details: nil)
      super(message)
      @status = status
      @code = code
      @details = details
    end

    def as_json
      {
        error: {
          code: code,
          message: message,
          status: status,
          details: details
        }.compact
      }
    end
  end

  class BadRequest < BaseError
    def initialize(message = 'Bad request', details: nil)
      super(message, status: 400, code: 'bad_request', details: details)
    end
  end

  class Unauthorized < BaseError
    def initialize(message = 'Unauthorized', details: nil)
      super(message, status: 401, code: 'unauthorized', details: details)
    end
  end

  class Forbidden < BaseError
    def initialize(message = 'Forbidden', details: nil)
      super(message, status: 403, code: 'forbidden', details: details)
    end
  end

  class NotFound < BaseError
    def initialize(message = 'Resource not found', details: nil)
      super(message, status: 404, code: 'not_found', details: details)
    end
  end

  class Conflict < BaseError
    def initialize(message = 'Resource conflict', details: nil)
      super(message, status: 409, code: 'conflict', details: details)
    end
  end

  class UnprocessableEntity < BaseError
    def initialize(message = 'Validation failed', details: nil)
      super(message, status: 422, code: 'unprocessable_entity', details: details)
    end
  end

  class TooManyRequests < BaseError
    def initialize(message = 'Rate limit exceeded', details: nil)
      super(message, status: 429, code: 'too_many_requests', details: details)
    end
  end

  class ServiceUnavailable < BaseError
    def initialize(message = 'Service unavailable', details: nil)
      super(message, status: 503, code: 'service_unavailable', details: details)
    end
  end
end
```

```ruby
# app/controllers/concerns/error_handler.rb
module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ApiErrors::BaseError, with: :handle_api_error
  end

  private

  def handle_api_error(exception)
    log_error(exception) if exception.status >= 500

    render json: exception.as_json, status: exception.status
  end
end
```

Usage in controllers:

```ruby
def create
  @user = User.new(user_params)

  raise ApiErrors::UnprocessableEntity.new(
    'User could not be created',
    details: @user.errors.as_json
  ) unless @user.save

  render json: { data: UserBlueprint.render_as_hash(@user) }, status: :created
end
```

### Step 7: Implement Authentication

#### Token-Based Authentication

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  def regenerate_api_token
    regenerate_api_token
  end
end
```

```ruby
# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_request, only: [:login, :register]

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          render json: {
            data: {
              user: UserBlueprint.render_as_hash(user, view: :detailed),
              token: user.api_token
            },
            message: 'Login successful'
          }
        else
          render json: {
            error: {
              code: 'invalid_credentials',
              message: 'Invalid email or password',
              status: 401
            }
          }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)

        if user.save
          render json: {
            data: {
              user: UserBlueprint.render_as_hash(user, view: :detailed),
              token: user.api_token
            },
            message: 'Registration successful'
          }, status: :created
        else
          render json: {
            error: {
              code: 'validation_failed',
              message: 'Registration failed',
              status: 422,
              details: user.errors.as_json
            }
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/auth/logout
      def logout
        current_user.regenerate_api_token
        head :no_content
      end

      # GET /api/v1/auth/me
      def me
        render json: {
          data: UserBlueprint.render_as_hash(current_user, view: :detailed)
        }
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :username)
      end
    end
  end
end
```

#### JWT Authentication

```ruby
# Gemfile
gem 'jwt'
```

```ruby
# lib/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
```

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      header = request.headers['Authorization']
      token = header.split(' ').last if header

      begin
        decoded = JsonWebToken.decode(token)
        @current_user = User.find(decoded[:user_id]) if decoded
      rescue ActiveRecord::RecordNotFound, JWT::DecodeError
        @current_user = nil
      end

      render_unauthorized unless @current_user
    end

    def current_user
      @current_user
    end

    def render_unauthorized
      render json: {
        error: {
          code: 'unauthorized',
          message: 'Invalid or expired token',
          status: 401
        }
      }, status: :unauthorized
    end
  end
end
```

```ruby
# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_request, only: [:login, :register]

      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            data: {
              user: UserBlueprint.render_as_hash(user, view: :detailed),
              token: token,
              expires_at: 24.hours.from_now
            },
            message: 'Login successful'
          }
        else
          render json: {
            error: {
              code: 'invalid_credentials',
              message: 'Invalid email or password',
              status: 401
            }
          }, status: :unauthorized
        end
      end

      def refresh
        token = JsonWebToken.encode(user_id: current_user.id)
        render json: {
          data: {
            token: token,
            expires_at: 24.hours.from_now
          }
        }
      end
    end
  end
end
```

#### OAuth 2.0 with Doorkeeper

```ruby
# Gemfile
gem 'doorkeeper'
```

```bash
rails generate doorkeeper:install
rails generate doorkeeper:migration
rails db:migrate
```

```ruby
# config/initializers/doorkeeper.rb
Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    User.find_by(id: session[:user_id]) || redirect_to(new_login_url)
  end

  admin_authenticator do
    User.find_by(id: session[:user_id])&.admin? || redirect_to(new_login_url)
  end

  access_token_expires_in 2.hours
  use_refresh_token

  grant_flows %w[authorization_code client_credentials password]

  skip_authorization do |resource_owner, client|
    client.application.trusted?
  end
end
```

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    before_action :doorkeeper_authorize!

    private

    def current_user
      @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end
  end
end
```

### Step 8: Implement Rate Limiting

#### Using Rack::Attack

```ruby
# Gemfile
gem 'rack-attack'
```

```ruby
# config/application.rb
config.middleware.use Rack::Attack
```

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle all requests by IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle API requests by API token
  throttle('api/token', limit: 100, period: 1.hour) do |req|
    if req.path.start_with?('/api')
      req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    end
  end

  # Throttle login attempts
  throttle('logins/ip', limit: 5, period: 20.minutes) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.ip
    end
  end

  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.params['email'].to_s.downcase.presence
    end
  end

  # Block requests from known bad actors
  blocklist('block bad actors') do |req|
    # Redis based blocking
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 10.minutes, bantime: 1.hour) do
      req.path.start_with?('/api') && req.get?
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    now = Time.zone.now
    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_s
    }

    body = {
      error: {
        code: 'too_many_requests',
        message: 'Rate limit exceeded. Please try again later.',
        status: 429
      }
    }.to_json

    [429, headers, [body]]
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [:throttle, :blocklist].include?(req.env['rack.attack.match_type'])
      Rails.logger.warn(
        "Rack::Attack #{req.env['rack.attack.match_type']}: " \
        "#{req.ip} #{req.request_method} #{req.fullpath}"
      )
    end
  end
end
```

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  namespace: 'rack_attack'
}
```

#### Custom Rate Limiter

```ruby
# app/services/rate_limiter.rb
class RateLimiter
  def initialize(identifier:, limit:, period:)
    @identifier = identifier
    @limit = limit
    @period = period
  end

  def exceeded?
    current_count >= @limit
  end

  def increment!
    Rails.cache.increment(cache_key, 1, expires_in: @period)
  end

  def reset!
    Rails.cache.delete(cache_key)
  end

  def current_count
    Rails.cache.read(cache_key) || 0
  end

  def remaining
    [@limit - current_count, 0].max
  end

  def reset_at
    ttl = Rails.cache.redis.ttl(cache_key)
    ttl.positive? ? Time.zone.now + ttl.seconds : Time.zone.now
  end

  private

  def cache_key
    "rate_limit:#{@identifier}:#{@period}"
  end
end
```

```ruby
# app/controllers/concerns/rate_limitable.rb
module RateLimitable
  extend ActiveSupport::Concern

  def check_rate_limit(identifier:, limit:, period:)
    limiter = RateLimiter.new(
      identifier: identifier,
      limit: limit,
      period: period
    )

    if limiter.exceeded?
      render_rate_limit_error(limiter)
      return false
    end

    limiter.increment!
    set_rate_limit_headers(limiter)
    true
  end

  private

  def render_rate_limit_error(limiter)
    render json: {
      error: {
        code: 'too_many_requests',
        message: 'Rate limit exceeded',
        status: 429
      }
    }, status: :too_many_requests
  end

  def set_rate_limit_headers(limiter)
    response.headers['X-RateLimit-Limit'] = limiter.limit.to_s
    response.headers['X-RateLimit-Remaining'] = limiter.remaining.to_s
    response.headers['X-RateLimit-Reset'] = limiter.reset_at.to_i.to_s
  end
end
```

Usage in controllers:

```ruby
class Api::V1::UsersController < Api::BaseController
  include RateLimitable

  before_action :check_user_rate_limit, only: [:create, :update]

  def check_user_rate_limit
    check_rate_limit(
      identifier: "user:#{current_user.id}:writes",
      limit: 10,
      period: 1.hour
    )
  end
end
```

### Step 9: Implement Filtering, Sorting, and Searching

#### Filtering with Query Parameters

```ruby
# app/controllers/api/v1/posts_controller.rb
def index
  posts = Post.includes(:user, :tags)

  # Apply filters
  posts = apply_filters(posts)

  # Apply sorting
  posts = apply_sorting(posts)

  @pagy, @posts = pagy(posts)

  render json: {
    data: PostBlueprint.render_as_hash(@posts),
    meta: pagination_meta(@pagy),
    filters: applied_filters
  }
end

private

def apply_filters(scope)
  scope = scope.where(published: true) if params[:published] == 'true'
  scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
  scope = scope.where('created_at >= ?', params[:from_date]) if params[:from_date].present?
  scope = scope.where('created_at <= ?', params[:to_date]) if params[:to_date].present?

  if params[:tags].present?
    tag_ids = params[:tags].split(',')
    scope = scope.joins(:tags).where(tags: { id: tag_ids })
  end

  if params[:search].present?
    scope = scope.where(
      'title ILIKE :query OR body ILIKE :query',
      query: "%#{params[:search]}%"
    )
  end

  scope
end

def apply_sorting(scope)
  sort_column = params[:sort_by] || 'created_at'
  sort_direction = params[:sort_order]&.downcase == 'asc' ? 'asc' : 'desc'

  allowed_columns = %w[created_at updated_at title published_at]
  sort_column = 'created_at' unless allowed_columns.include?(sort_column)

  scope.order("#{sort_column} #{sort_direction}")
end

def applied_filters
  {
    published: params[:published],
    user_id: params[:user_id],
    tags: params[:tags],
    search: params[:search],
    from_date: params[:from_date],
    to_date: params[:to_date],
    sort_by: params[:sort_by] || 'created_at',
    sort_order: params[:sort_order] || 'desc'
  }.compact
end
```

#### Advanced Filtering with Ransack

```ruby
# Gemfile
gem 'ransack'
```

```ruby
# app/controllers/api/v1/posts_controller.rb
def index
  @q = Post.ransack(params[:q])
  @pagy, @posts = pagy(@q.result(distinct: true).includes(:user, :tags))

  render json: {
    data: PostBlueprint.render_as_hash(@posts),
    meta: pagination_meta(@pagy)
  }
end

# Example requests:
# GET /api/v1/posts?q[title_cont]=rails
# GET /api/v1/posts?q[created_at_gteq]=2024-01-01
# GET /api/v1/posts?q[user_username_eq]=john_doe
# GET /api/v1/posts?q[s]=created_at desc
```

#### Full-Text Search with pg_search

```ruby
# Gemfile
gem 'pg_search'
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_full_text,
    against: {
      title: 'A',      # Weight A (highest)
      body: 'B',       # Weight B
      excerpt: 'C'     # Weight C (lowest)
    },
    using: {
      tsearch: {
        prefix: true,
        dictionary: 'english'
      }
    },
    associated_against: {
      user: [:username, :email],
      tags: [:name]
    }
end
```

```ruby
# app/controllers/api/v1/search_controller.rb
module Api
  module V1
    class SearchController < BaseController
      skip_before_action :authenticate_request

      # GET /api/v1/search?q=rails&type=posts
      def index
        query = params[:q]
        type = params[:type] || 'all'

        return render_empty_results if query.blank?

        results = case type
        when 'posts'
          search_posts(query)
        when 'users'
          search_users(query)
        when 'all'
          search_all(query)
        else
          render_invalid_type and return
        end

        render json: { data: results, meta: { query: query, type: type } }
      end

      private

      def search_posts(query)
        posts = Post.search_full_text(query).limit(20)
        {
          posts: PostBlueprint.render_as_hash(posts, view: :simple)
        }
      end

      def search_users(query)
        users = User.search_full_text(query).limit(20)
        {
          users: UserBlueprint.render_as_hash(users, view: :simple)
        }
      end

      def search_all(query)
        {
          posts: PostBlueprint.render_as_hash(Post.search_full_text(query).limit(10), view: :simple),
          users: UserBlueprint.render_as_hash(User.search_full_text(query).limit(10), view: :simple)
        }
      end

      def render_empty_results
        render json: { data: {}, meta: { query: '', type: params[:type] } }
      end

      def render_invalid_type
        render json: {
          error: {
            code: 'bad_request',
            message: 'Invalid search type. Must be one of: posts, users, all',
            status: 400
          }
        }, status: :bad_request
      end
    end
  end
end
```

### Step 10: Implement Caching

#### HTTP Caching with ETags

```ruby
# app/controllers/api/v1/users_controller.rb
def show
  @user = User.find(params[:id])

  if stale?(etag: @user, last_modified: @user.updated_at)
    render json: {
      data: UserBlueprint.render_as_hash(@user, view: :detailed)
    }
  end
end
```

#### Fragment Caching with Russian Doll Caching

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user, touch: true
  has_many :comments, dependent: :destroy

  after_commit :bust_cache

  def cache_key_with_version
    "posts/#{id}-#{updated_at.to_i}"
  end

  private

  def bust_cache
    Rails.cache.delete(['posts', id])
  end
end
```

```ruby
# app/controllers/api/v1/posts_controller.rb
def show
  @post = Post.find(params[:id])

  json = Rails.cache.fetch(['posts', @post.id, @post.updated_at]) do
    PostBlueprint.render(@post, view: :detailed)
  end

  render json: { data: JSON.parse(json) }
end
```

#### Low-Level Caching

```ruby
# app/controllers/api/v1/users_controller.rb
def followers
  @user = User.find(params[:id])

  follower_ids = Rails.cache.fetch(['user_followers', @user.id], expires_in: 5.minutes) do
    @user.follower_ids
  end

  @followers = User.where(id: follower_ids)

  render json: {
    data: UserBlueprint.render_as_hash(@followers, view: :simple)
  }
end
```

#### Cache Invalidation Patterns

```ruby
# app/models/concerns/cacheable.rb
module Cacheable
  extend ActiveSupport::Concern

  included do
    after_commit :clear_cache
  end

  def cache_key_with_version
    "#{self.class.name.downcase.pluralize}/#{id}-#{updated_at.to_i}"
  end

  def clear_cache
    Rails.cache.delete([self.class.name.downcase.pluralize, id])
    clear_association_caches
  end

  def clear_association_caches
    # Override in models to clear related caches
  end
end
```

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include Cacheable

  belongs_to :user

  private

  def clear_association_caches
    Rails.cache.delete(['user_posts', user_id])
  end
end
```

### Step 11: API Documentation with OpenAPI/Swagger

#### Using rswag

```ruby
# Gemfile
gem 'rswag'
gem 'rswag-api'
gem 'rswag-ui'

group :development, :test do
  gem 'rswag-specs'
end
```

```bash
rails g rswag:install
rails g rswag:specs:install
```

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
        description: 'API documentation for MyApp V1'
      },
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'api.example.com'
            }
          }
        }
      ],
      paths: {},
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          },
          api_key: {
            type: :apiKey,
            name: 'Authorization',
            in: :header
          }
        },
        schemas: {
          user: {
            type: :object,
            properties: {
              id: { type: :integer },
              username: { type: :string },
              email: { type: :string },
              created_at: { type: :string, format: :datetime }
            },
            required: ['id', 'username', 'email']
          },
          post: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              body: { type: :string },
              published: { type: :boolean },
              created_at: { type: :string, format: :datetime }
            },
            required: ['id', 'title', 'body']
          },
          error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: { type: :string },
                  message: { type: :string },
                  status: { type: :integer },
                  details: { type: :object }
                }
              }
            }
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
```

```ruby
# spec/requests/api/v1/users_spec.rb
require 'swagger_helper'

RSpec.describe 'api/v1/users', type: :request do
  path '/api/v1/users' do
    get('list users') do
      tags 'Users'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: { '$ref' => '#/components/schemas/user' }
            },
            meta: {
              type: :object,
              properties: {
                current_page: { type: :integer },
                total_pages: { type: :integer },
                total_count: { type: :integer },
                per_page: { type: :integer }
              }
            }
          },
          required: ['data', 'meta']

        let(:page) { 1 }
        let(:per_page) { 20 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
          expect(data['meta']).to include('current_page', 'total_pages')
        end
      end
    end

    post('create user') do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              username: { type: :string },
              email: { type: :string },
              password: { type: :string },
              password_confirmation: { type: :string }
            },
            required: ['username', 'email', 'password', 'password_confirmation']
          }
        }
      }

      response(201, 'created') do
        let(:user) do
          {
            user: {
              username: 'johndoe',
              email: 'john@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        run_test!
      end

      response(422, 'unprocessable entity') do
        schema '$ref' => '#/components/schemas/error'

        let(:user) do
          {
            user: {
              username: '',
              email: 'invalid',
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

    get('show user') do
      tags 'Users'
      produces 'application/json'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            data: { '$ref' => '#/components/schemas/user' }
          }

        let(:id) { create(:user).id }
        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/error'
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
end
```

Generate documentation:

```bash
SWAGGER_DRY_RUN=0 rails rswag:specs:swaggerize
```

Access Swagger UI at: `http://localhost:3000/api-docs`

## Best Practices

### 1. Use Consistent Naming Conventions

```ruby
# Good: Plural resource names
GET /api/v1/users
GET /api/v1/posts

# Bad: Singular or mixed
GET /api/v1/user
GET /api/v1/post
```

### 2. Version from Day One

Always version your API, even if you only have one version:

```ruby
# Good
GET /api/v1/users

# Bad
GET /api/users
```

### 3. Use Proper HTTP Status Codes

```ruby
# Success codes
200 OK              # GET, PUT, PATCH success
201 Created         # POST success
204 No Content      # DELETE success
304 Not Modified    # Cached response

# Client error codes
400 Bad Request     # Malformed request
401 Unauthorized    # Missing/invalid authentication
403 Forbidden       # Authenticated but not authorized
404 Not Found       # Resource doesn't exist
422 Unprocessable   # Validation errors
429 Too Many Requests # Rate limit exceeded

# Server error codes
500 Internal Server Error
503 Service Unavailable
```

### 4. Return Consistent Error Responses

```ruby
# Always use the same error structure
{
  "error": {
    "code": "validation_failed",
    "message": "User could not be created",
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

### 5. Use Proper Authentication

```ruby
# Good: Bearer token in header
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Bad: Token in URL
GET /api/v1/users?token=abc123
```

### 6. Include Metadata in List Responses

```ruby
{
  "data": [...],
  "meta": {
    "current_page": 2,
    "total_pages": 10,
    "total_count": 200,
    "per_page": 20
  },
  "links": {
    "first": "...",
    "prev": "...",
    "self": "...",
    "next": "...",
    "last": "..."
  }
}
```

### 7. Use Includes for Related Resources

```ruby
# Allow clients to request related data
GET /api/v1/posts?include=user,comments

# app/controllers/api/v1/posts_controller.rb
def index
  posts = Post.all
  posts = posts.includes(:user) if params[:include]&.include?('user')
  posts = posts.includes(:comments) if params[:include]&.include?('comments')

  @pagy, @posts = pagy(posts)

  view = params[:include].present? ? :detailed : :default

  render json: {
    data: PostBlueprint.render_as_hash(@posts, view: view)
  }
end
```

### 8. Implement Field Selection (Sparse Fieldsets)

```ruby
# Allow clients to request specific fields
GET /api/v1/users?fields=id,username,email

# app/controllers/api/v1/users_controller.rb
def index
  @users = User.all

  if params[:fields].present?
    fields = params[:fields].split(',').map(&:to_sym)
    data = @users.map { |user| user.slice(*fields) }
  else
    data = UserBlueprint.render_as_hash(@users)
  end

  render json: { data: data }
end
```

### 9. Document Everything

- Use OpenAPI/Swagger for interactive documentation
- Include examples for every endpoint
- Document error responses
- Provide code samples in multiple languages
- Keep documentation in sync with code

### 10. Monitor API Usage

```ruby
# Track API metrics
# app/controllers/api/base_controller.rb
after_action :track_api_usage

private

def track_api_usage
  ApiMetric.create(
    endpoint: "#{controller_name}##{action_name}",
    method: request.method,
    status: response.status,
    duration: (Time.current - @request_start_time) * 1000,
    user_id: current_user&.id,
    ip_address: request.remote_ip,
    user_agent: request.user_agent
  )
end
```

### 11. Implement Internationalization (I18n) Properly

APIs serving international audiences should support multiple locales for error messages, validation messages, and other user-facing content. Use thread-safe locale switching to prevent locale leaking between requests.

#### Thread-Safe Locale Switching

**❌ Bad: Using `before_action` with direct assignment**

```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  before_action :set_locale

  private

  def set_locale
    # PROBLEM: In multi-threaded environments (Puma), this can leak
    # the locale from one request to another if threads are reused
    I18n.locale = params[:locale] || :en
  end
end
```

**✅ Good: Using `around_action` with `I18n.with_locale`**

```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ApplicationController
  around_action :switch_locale

  private

  # Thread-safe locale switching: locale is scoped to this request only
  # and automatically reverted after the action completes
  def switch_locale(&action)
    I18n.with_locale(detect_locale, &action)
  end

  # Override this method in subclasses to customize locale detection
  def detect_locale
    # Priority: query param > Accept-Language header > default
    locale = params[:locale].presence ||
             request.headers["Accept-Language"]&.split(",")&.first&.split("-")&.first

    # Validate against supported locales
    I18n.available_locales.include?(locale&.to_sym) ? locale.to_sym : I18n.default_locale
  end
end
```

#### Locale Detection Strategies

**1. Query Parameter (Explicit)**

```ruby
# Client specifies locale in URL
GET /api/v1/users?locale=ar
GET /api/v1/users?locale=en
```

**2. Accept-Language Header (Standard)**

```ruby
# Client sends HTTP header
GET /api/v1/users
Accept-Language: ar-SA,ar;q=0.9,en;q=0.8

# In controller
def detect_locale
  header = request.headers["Accept-Language"]
  locale = header&.split(",")&.first&.split("-")&.first
  locale&.to_sym || :en
end
```

**3. Subdomain (Permanent)**

```ruby
# ar.example.com, en.example.com
def detect_locale
  subdomain = request.subdomain
  subdomain.presence&.to_sym || :en
end
```

**4. User Preferences (Authenticated)**

```ruby
def detect_locale
  current_user&.preferred_locale || detect_locale_from_header
end
```

#### Customizing Locale per Controller

Some controllers may need to override the default locale detection:

```ruby
# app/controllers/api/v1/webhooks/wati_controller.rb
class Api::V1::Webhooks::WatiController < Api::BaseController
  # Override detect_locale to always use Arabic for WhatsApp webhooks
  # since our customer base is primarily Arabic-speaking
  def detect_locale
    :ar
  end
end
```

#### Localized Error Messages

**Setup locale files:**

```yaml
# config/locales/validations.en.yml
en:
  validations:
    required: "%{field} is required"
    invalid_email: "%{field} must be a valid email address"
    invalid_phone: "%{field} must be a valid phone number"
```

```yaml
# config/locales/validations.ar.yml
ar:
  validations:
    required: "%{field} مطلوب"
    invalid_email: "%{field} يجب أن يكون عنوان بريد إلكتروني صحيح"
    invalid_phone: "%{field} يجب أن يكون رقم هاتف صحيح"
```

**Use in validators:**

```ruby
# app/validators/my_validator.rb
class MyValidator
  def validate_required(field, value)
    return if value.present?

    # I18n.locale is automatically set by around_action
    I18n.t("validations.required", field: field_label(field))
  end

  private

  def field_label(field)
    # Return localized field name
    I18n.locale == :ar ? @model.label_ar : @model.label_en
  end
end
```

#### Testing Locale Switching

**Test locale detection:**

```ruby
# spec/controllers/api/base_controller_spec.rb
RSpec.describe Api::BaseController, type: :controller do
  controller do
    def index
      render json: { message: I18n.t("test.message") }
    end
  end

  describe "locale switching" do
    it "uses locale from query param" do
      get :index, params: { locale: "ar" }
      expect(I18n.locale).to eq(:ar)
    end

    it "uses locale from Accept-Language header" do
      request.headers["Accept-Language"] = "ar-SA,ar;q=0.9"
      get :index
      expect(I18n.locale).to eq(:ar)
    end

    it "prefers query param over Accept-Language header" do
      request.headers["Accept-Language"] = "ar"
      get :index, params: { locale: "en" }
      expect(I18n.locale).to eq(:en)
    end

    it "defaults to English when no locale specified" do
      get :index
      expect(I18n.locale).to eq(:en)
    end

    it "does not leak locale between requests" do
      # First request in Arabic
      get :index, params: { locale: "ar" }
      first_locale = I18n.locale

      # Second request with no locale
      get :index
      second_locale = I18n.locale

      # Locale should reset to default, not persist
      expect(first_locale).to eq(:ar)
      expect(second_locale).to eq(:en)
    end
  end
end
```

**Test localized validation messages:**

```ruby
# spec/requests/api/v1/users_spec.rb
RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users" do
    context "with Arabic locale" do
      it "returns validation errors in Arabic" do
        post "/api/v1/users?locale=ar",
             params: { user: { email: "" } },
             headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]["email"]).to include("البريد الإلكتروني مطلوب")
      end
    end

    context "with English locale" do
      it "returns validation errors in English" do
        post "/api/v1/users?locale=en",
             params: { user: { email: "" } },
             headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]["email"]).to include("Email is required")
      end
    end
  end
end
```

#### Why `around_action` + `I18n.with_locale`?

1. **Thread Safety**: Puma runs multiple threads. Direct `I18n.locale=` assignment can cause locale to leak between requests if threads are reused.

2. **Automatic Cleanup**: `I18n.with_locale` automatically reverts the locale after the block executes, even if an exception is raised.

3. **Rails Best Practice**: Documented in the [Rails I18n Guide](https://guides.rubyonrails.org/i18n.html#managing-the-locale-across-requests).

**What can go wrong without it:**

```ruby
# Thread 1: Arabic request
I18n.locale = :ar  # Sets global state

# Thread 1: Processing... (takes 500ms)

# Thread 2: English request (reuses Thread 1 after it finishes)
# Thread 2 now has I18n.locale = :ar from previous request!
# English user sees Arabic error messages
```

#### API Response Example

**Request:**
```http
GET /api/v1/users/123?locale=ar
```

**Response (Arabic):**
```json
{
  "error": {
    "code": "not_found",
    "message": "لم يتم العثور على المستخدم",
    "status": 404
  }
}
```

**Request:**
```http
GET /api/v1/users/123?locale=en
```

**Response (English):**
```json
{
  "error": {
    "code": "not_found",
    "message": "User not found",
    "status": 404
  }
}
```

## Common Mistakes

### 1. Not Handling N+1 Queries

```ruby
# Bad: N+1 query
def index
  @users = User.all
  # Later: @users.each { |u| u.posts } causes N+1
end

# Good: Eager load associations
def index
  @users = User.includes(:posts, :profile)
end
```

### 2. Returning Database IDs in URLs

```ruby
# Bad: Sequential IDs expose business metrics
GET /api/v1/users/1
GET /api/v1/users/2

# Good: Use UUIDs or obfuscated IDs
GET /api/v1/users/550e8400-e29b-41d4-a716-446655440000

# app/models/user.rb
class User < ApplicationRecord
  before_create :generate_uuid

  def to_param
    uuid
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
```

### 3. Not Validating Input

```ruby
# Bad: No validation
def create
  @user = User.create(params[:user])
end

# Good: Use strong parameters and validations
def create
  @user = User.new(user_params)
  if @user.save
    render json: { data: UserBlueprint.render_as_hash(@user) }, status: :created
  else
    render json: { error: { details: @user.errors } }, status: :unprocessable_entity
  end
end

private

def user_params
  params.require(:user).permit(:email, :username, :password)
end
```

### 4. Exposing Sensitive Data

```ruby
# Bad: Exposing password digest
class UserBlueprint < ApplicationBlueprint
  fields :id, :email, :password_digest # Don't do this!
end

# Good: Explicitly list safe fields
class UserBlueprint < ApplicationBlueprint
  fields :id, :email, :username, :created_at

  # Conditionally show email only to owner/admin
  field :email, if: ->(_, user, options) {
    options[:current_user]&.id == user.id || options[:current_user]&.admin?
  }
end
```

### 5. Not Implementing Idempotency

```ruby
# Bad: POST creating multiple resources
def create
  @user = User.create!(user_params)
  render json: { data: UserBlueprint.render_as_hash(@user) }, status: :created
end

# Good: Use idempotency keys
def create
  idempotency_key = request.headers['Idempotency-Key']

  if idempotency_key
    cached = Rails.cache.read("idempotency:#{idempotency_key}")
    return render json: cached[:body], status: cached[:status] if cached
  end

  @user = User.create!(user_params)
  response_body = { data: UserBlueprint.render_as_hash(@user) }

  if idempotency_key
    Rails.cache.write(
      "idempotency:#{idempotency_key}",
      { body: response_body, status: 201 },
      expires_in: 24.hours
    )
  end

  render json: response_body, status: :created
end
```

### 6. Not Handling Timezones

```ruby
# Bad: Using Time.now
def create
  @post = Post.create!(published_at: Time.now)
end

# Good: Use Time.zone
def create
  @post = Post.create!(published_at: Time.zone.now)
end
```

### 7. Inconsistent Date Formats

```ruby
# Bad: Inconsistent formats
created_at: "2024-01-15"
updated_at: "01/15/2024"

# Good: Always use ISO 8601
# config/initializers/blueprinter.rb
Blueprinter.configure do |config|
  config.datetime_format = ->(datetime) { datetime.iso8601 }
end

# Output: "2024-01-15T10:30:00Z"
```

### 8. Not Implementing CORS Properly

```ruby
# Bad: Allowing all origins in production
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :any
  end
end

# Good: Whitelist specific origins
config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['ALLOWED_ORIGINS'].split(',')
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 600
  end
end
```

### 9. Not Using Bulk Operations

```ruby
# Bad: Creating records one by one
def bulk_create
  params[:users].each do |user_params|
    User.create!(user_params) # N database calls
  end
end

# Good: Use bulk insert
def bulk_create
  users_data = params[:users].map do |user_params|
    {
      username: user_params[:username],
      email: user_params[:email],
      created_at: Time.zone.now,
      updated_at: Time.zone.now
    }
  end

  User.insert_all!(users_data) # Single database call
end
```

### 10. Not Handling Concurrent Requests

```ruby
# Bad: Race condition
def follow
  @user = User.find(params[:id])
  unless current_user.following?(@user)
    current_user.follow(@user)
  end
end

# Good: Use unique constraints and handle errors
def follow
  @user = User.find(params[:id])

  begin
    current_user.follow(@user)
    render json: { following: true }
  rescue ActiveRecord::RecordNotUnique
    render json: { following: true, message: 'Already following' }
  end
end

# Migration
add_index :follows, [:follower_id, :followee_id], unique: true
```

## Testing APIs

### Request Specs with RSpec

```ruby
# spec/requests/api/v1/users_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/users' do
    before do
      create_list(:user, 15)
    end

    it 'returns a list of users' do
      get '/api/v1/users', headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data'].size).to eq(15)
      expect(json_response['meta']).to include(
        'current_page' => 1,
        'total_count' => 15
      )
    end

    it 'paginates results' do
      get '/api/v1/users', params: { page: 2, per_page: 5 }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data'].size).to eq(5)
      expect(json_response['meta']['current_page']).to eq(2)
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'returns a user' do
      get "/api/v1/users/#{user.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['id']).to eq(user.id)
      expect(json_response['data']['username']).to eq(user.username)
    end

    it 'returns 404 for non-existent user' do
      get '/api/v1/users/999999', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']['code']).to eq('not_found')
    end
  end

  describe 'POST /api/v1/users' do
    let(:valid_params) do
      {
        user: {
          username: 'newuser',
          email: 'new@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    it 'creates a new user' do
      expect {
        post '/api/v1/users', params: valid_params, headers: headers
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['username']).to eq('newuser')
    end

    it 'returns validation errors for invalid data' do
      invalid_params = { user: { username: '', email: 'invalid' } }

      post '/api/v1/users', params: invalid_params, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']['code']).to eq('validation_failed')
      expect(json_response['error']['details']).to be_present
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    it 'updates a user' do
      patch "/api/v1/users/#{user.id}",
        params: { user: { username: 'updated' } },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['username']).to eq('updated')
      expect(user.reload.username).to eq('updated')
    end
  end

  describe 'DELETE /api/v1/users/:id' do
    it 'deletes a user' do
      expect {
        delete "/api/v1/users/#{user.id}", headers: headers
      }.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
```

### Testing Authentication

```ruby
# spec/requests/api/v1/auth_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let(:user) { create(:user, password: 'password123') }

  describe 'POST /api/v1/auth/login' do
    it 'returns a token for valid credentials' do
      post '/api/v1/auth/login', params: {
        email: user.email,
        password: 'password123'
      }

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['token']).to be_present
      expect(json_response['data']['user']['id']).to eq(user.id)
    end

    it 'returns unauthorized for invalid credentials' do
      post '/api/v1/auth/login', params: {
        email: user.email,
        password: 'wrong'
      }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']['code']).to eq('invalid_credentials')
    end
  end
end
```

### Testing Rate Limiting

```ruby
# spec/requests/api/v1/rate_limiting_spec.rb
require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    allow(Rack::Attack).to receive(:enabled).and_return(true)
  end

  it 'allows requests within the limit' do
    5.times do
      post '/api/v1/posts', params: { post: attributes_for(:post) }, headers: headers
      expect(response).to have_http_status(:created)
    end
  end

  it 'blocks requests exceeding the limit' do
    11.times do |i|
      post '/api/v1/posts', params: { post: attributes_for(:post) }, headers: headers

      if i < 10
        expect(response).to have_http_status(:created)
      else
        expect(response).to have_http_status(:too_many_requests)
        expect(json_response['error']['code']).to eq('too_many_requests')
      end
    end
  end
end
```

## Performance Optimization

### 1. Use Database Indexes

```ruby
# db/migrate/xxx_add_indexes.rb
class AddIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :posts, :user_id
    add_index :posts, :published
    add_index :posts, :created_at
    add_index :posts, [:user_id, :published]

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
```

### 2. Use Database Projections

```ruby
# Bad: Loading all columns
def index
  @users = User.all
end

# Good: Select only needed columns
def index
  @users = User.select(:id, :username, :email, :avatar_url)
end
```

### 3. Use Counter Caches

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :posts, counter_cache: true
end

# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Migration
add_column :users, :posts_count, :integer, default: 0, null: false

# Backfill existing counts
User.find_each do |user|
  User.reset_counters(user.id, :posts)
end
```

### 4. Use Background Jobs for Heavy Operations

```ruby
# Bad: Synchronous email sending
def create
  @user = User.create!(user_params)
  UserMailer.welcome_email(@user).deliver_now # Blocks request
  render json: { data: UserBlueprint.render_as_hash(@user) }, status: :created
end

# Good: Background job
def create
  @user = User.create!(user_params)
  UserMailer.welcome_email(@user).deliver_later # Non-blocking
  render json: { data: UserBlueprint.render_as_hash(@user) }, status: :created
end
```

### 5. Implement Response Compression

```ruby
# config/application.rb
config.middleware.use Rack::Deflater
```

### 6. Use JSON Streaming for Large Responses

```ruby
# app/controllers/api/v1/exports_controller.rb
def export_users
  response.headers['Content-Type'] = 'application/json'
  response.headers['Content-Disposition'] = 'attachment; filename="users.json"'

  self.response_body = Enumerator.new do |yielder|
    yielder << '{"data":['

    User.find_each.with_index do |user, index|
      yielder << ',' if index > 0
      yielder << UserBlueprint.render(user)
    end

    yielder << ']}'
  end
end
```

## Security Best Practices

### 1. Validate and Sanitize All Input

```ruby
# Use strong parameters
def user_params
  params.require(:user).permit(:email, :username, :bio)
end
```

### 2. Use HTTPS Only

```ruby
# config/environments/production.rb
config.force_ssl = true
```

### 3. Implement CSRF Protection for Cookie-Based Auth

```ruby
# app/controllers/api/base_controller.rb
class BaseController < ActionController::API
  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception
end
```

### 4. Set Security Headers

```ruby
# config/application.rb
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'DENY',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block',
  'Referrer-Policy' => 'strict-origin-when-cross-origin'
}
```

### 5. Implement API Key Rotation

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def rotate_api_key!
    regenerate_api_token
    ApiKeyRotationJob.perform_later(user_id: id, old_token: api_token_was)
  end
end
```

## Conclusion

Building production-grade REST APIs requires careful attention to design patterns, error handling, performance, and security. This guide provides a comprehensive foundation, but always:

- Monitor your API in production
- Gather user feedback
- Iterate on your design
- Keep documentation updated
- Stay consistent with conventions
- Prioritize developer experience

Remember: A well-designed API is intuitive, consistent, performant, and secure.
