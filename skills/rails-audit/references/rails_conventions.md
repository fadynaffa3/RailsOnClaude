# Rails Conventions & Patterns

Best practices for following Rails conventions and avoiding common Rails anti-patterns.

## RESTful Routing

### Prefer Resource Routes
```ruby
# Bad - custom actions everywhere
get "/users/list"
post "/users/add"
get "/users/find/:id"
post "/users/delete/:id"

# Good - RESTful resources
resources :users  # automatically creates index, show, new, create, edit, update, destroy
```

### Limit Custom Actions
```ruby
# Bad - too many custom actions
resources :posts do
  member do
    get :preview
    get :stats
    post :duplicate
    post :archive
    post :unarchive
    post :feature
    post :unfeature
  end
end

# Good - use nested resources or separate controllers
resources :posts do
  resource :archive, only: [:create, :destroy]
  resource :preview, only: :show
end

resources :post_stats, only: :show
```

## Controller Patterns

### Keep Controllers Thin
```ruby
# Bad - business logic in controller
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    @order.user_id = current_user.id
    @order.total = calculate_total(@order.items)
    
    if @order.save
      @order.items.each do |item|
        item.update(status: "ordered")
        InventoryItem.find_by(product_id: item.product_id).decrement!(:quantity)
      end
      
      OrderMailer.confirmation(@order).deliver_later
      NotificationService.notify_admin(@order)
      
      render json: @order, status: :created
    else
      render json: @order.errors, status: :unprocessable_entity
    end
  end
end

# Good - extract to action/service
class OrdersController < ApplicationController
  def create
    result = Orders::Create.call(params: order_params, user: current_user)
    
    if result.success?
      render json: result.order, status: :created
    else
      render json: result.errors, status: :unprocessable_entity
    end
  end
end
```

### Use Strong Parameters
```ruby
# Bad - permits all parameters
def user_params
  params.require(:user).permit!
end

# Good - explicit permitted attributes
def user_params
  params.require(:user).permit(:name, :email, :bio)
end

# Good - with nested attributes
def post_params
  params.require(:post).permit(:title, :body, tag_ids: [], comments_attributes: [:id, :body, :_destroy])
end
```

### Use Before Actions for Common Setup
```ruby
# Bad - repeated code in actions
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    authorize @post
  end
  
  def edit
    @post = Post.find(params[:id])
    authorize @post
  end
  
  def update
    @post = Post.find(params[:id])
    authorize @post
    # ...
  end
end

# Good - use before_action
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_post, only: [:edit, :update, :destroy]
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  end
  
  def authorize_post
    authorize @post
  end
end
```

## Model Patterns

### Use Scopes for Queries
```ruby
# Bad - repeated queries in controllers
@active_users = User.where(status: "active")
@admin_users = User.where(role: "admin")

# Good - define scopes in model
class User < ApplicationRecord
  scope :active, -> { where(status: "active") }
  scope :admins, -> { where(role: "admin") }
  scope :created_after, ->(date) { where("created_at > ?", date) }
end

# Usage
@active_users = User.active
@recent_admins = User.admins.created_after(1.month.ago)
```

### Use Validations Properly
```ruby
# Bad - validation in controller
def create
  @user = User.new(user_params)
  
  if @user.email.present? && @user.email.include?("@")
    @user.save
  else
    # handle error
  end
end

# Good - validations in model
class User < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :username, uniqueness: true
end
```

### Avoid Callback Overload
```ruby
# Bad - too much logic in callbacks
class Order < ApplicationRecord
  after_create :send_confirmation_email
  after_create :notify_admin
  after_create :update_inventory
  after_create :create_invoice
  after_create :charge_payment
  after_create :update_analytics
  
  # 6 callbacks - hard to debug, order-dependent, slow
end

# Good - explicit orchestration
class Orders::Create
  def call(params:, user:)
    Order.transaction do
      order = Order.create!(params.merge(user: user))
      
      # Explicit steps
      charge_payment(order)
      update_inventory(order)
      create_invoice(order)
      
      # Background jobs for non-critical tasks
      OrderMailer.confirmation(order).deliver_later
      NotifyAdminJob.perform_later(order.id)
      AnalyticsJob.perform_later("order.created", order.id)
      
      order
    end
  end
end
```

### Use Concerns for Shared Behavior
```ruby
# Bad - duplicated code in models
class Post < ApplicationRecord
  belongs_to :user
  
  def archive!
    update!(archived_at: Time.current)
  end
  
  def archived?
    archived_at.present?
  end
end

class Comment < ApplicationRecord
  def archive!
    update!(archived_at: Time.current)
  end
  
  def archived?
    archived_at.present?
  end
end

# Good - extract to concern
module Archivable
  extend ActiveSupport::Concern
  
  included do
    scope :archived, -> { where.not(archived_at: nil) }
    scope :active, -> { where(archived_at: nil) }
  end
  
  def archive!
    update!(archived_at: Time.current)
  end
  
  def archived?
    archived_at.present?
  end
end

class Post < ApplicationRecord
  include Archivable
end

class Comment < ApplicationRecord
  include Archivable
end
```

## Background Jobs

### Move Slow Operations to Jobs
```ruby
# Bad - synchronous operations in request
def create
  @user = User.create!(user_params)
  UserMailer.welcome(@user).deliver_now  # Blocks request
  SlackNotifier.notify_team(@user)       # Blocks request
  AnalyticsService.track(@user)          # Blocks request
  
  render json: @user
end

# Good - async jobs
def create
  @user = User.create!(user_params)
  
  UserMailer.welcome(@user).deliver_later
  NotifyTeamJob.perform_later(@user.id)
  TrackAnalyticsJob.perform_later("user.created", @user.id)
  
  render json: @user
end
```

## Caching Strategies

### Fragment Caching
```ruby
# View caching
<% cache @post do %>
  <%= render @post %>
<% end %>

# Russian Doll caching
<% cache @post do %>
  <%= render @post %>
  
  <% cache @post.comments do %>
    <%= render @post.comments %>
  <% end %>
<% end %>
```

### Query Caching
```ruby
# Bad - no caching
def expensive_data
  User.joins(:posts).where(posts: { published: true }).count
end

# Good - cache the result
def expensive_data
  Rails.cache.fetch("users/published_posts_count", expires_in: 1.hour) do
    User.joins(:posts).where(posts: { published: true }).count
  end
end
```

## Database Patterns

### Add Database Indexes
```ruby
# Bad - no indexes on foreign keys
create_table :posts do |t|
  t.references :user  # No index!
  t.string :status
  t.timestamps
end

# Good - index foreign keys and frequently queried columns
create_table :posts do |t|
  t.references :user, index: true  # Or null: false, foreign_key: true
  t.string :status, index: true
  t.timestamps
end

# Add index on multiple columns for common queries
add_index :posts, [:user_id, :status]
add_index :posts, [:status, :published_at]
```

### Use Database-Level Constraints
```ruby
# Bad - only application-level validation
class User < ApplicationRecord
  validates :email, uniqueness: true
end

# Good - database constraint too
class AddUniqueIndexToUsersEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :email, unique: true
  end
end

class User < ApplicationRecord
  validates :email, uniqueness: true
end
```

## Internationalization

### Avoid Hardcoded Strings
```ruby
# Bad
flash[:notice] = "User was successfully created."

# Good
flash[:notice] = t(".success")

# en.yml:
# en:
#   users:
#     create:
#       success: "User was successfully created."
```

## Asset Management

### Use Asset Pipeline Properly
```ruby
# Bad - individual asset tags
<%= javascript_include_tag "jquery" %>
<%= javascript_include_tag "bootstrap" %>
<%= javascript_include_tag "app" %>

# Good - use application manifest
<%= javascript_include_tag "application" %>

# app/assets/config/manifest.js:
//= link application.js
//= link_tree ../images
//= link_tree ../builds
```

## Testing Conventions

### Follow Test Structure
```ruby
# Bad - unclear test
it "works" do
  user = User.create(name: "John")
  post = Post.create(user: user)
  post.publish
  expect(post.published?).to be true
end

# Good - Four Phase Test
it "publishes the post" do
  # Setup
  user = create(:user)
  post = create(:post, user: user, status: "draft")
  
  # Exercise
  post.publish
  
  # Verify
  expect(post).to be_published
  expect(post.published_at).to be_present
  
  # (Teardown handled by database_cleaner)
end
```

### Use Factories Over Fixtures
```ruby
# Bad - fixtures with brittle dependencies
# test/fixtures/users.yml
john:
  name: John Doe
  email: john@example.com
  
# Good - factories with explicit relationships
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    
    trait :admin do
      role { "admin" }
    end
  end
end

# Usage
user = create(:user, :admin)
```

## Security Conventions

### Use Parameterized Queries
```ruby
# Bad - SQL injection risk
User.where("email = '#{params[:email]}'")

# Good - parameterized
User.where("email = ?", params[:email])

# Better - hash syntax
User.where(email: params[:email])
```

### Sanitize User Input in Views
```ruby
# Bad - XSS vulnerability
<%= @comment.body.html_safe %>

# Good - sanitize
<%= sanitize @comment.body %>

# Or use safe helpers
<%= simple_format @comment.body %>
```

### Use CSRF Protection
```ruby
# Ensure in ApplicationController
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Or for API-only
  protect_from_forgery with: :null_session
end
```
