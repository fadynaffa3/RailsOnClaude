---
name: rails-code-reviewer
description: Comprehensive code review guidelines for Rails applications. PR review checklist, security review, performance review, and code quality standards.
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - code-review
  - security
  - performance
  - quality
  - pr-review
dependencies:
  - rails >= 7.0
---

# Rails Code Reviewer

A comprehensive guide for conducting thorough code reviews of Ruby on Rails applications. Covers PR review checklists, security concerns, performance considerations, code quality standards, and best practices for giving and receiving feedback.

## Use this skill when

- Reviewing pull requests
- Conducting security audits
- Performing performance reviews
- Establishing code review standards
- Training team members on code review
- Creating code review checklists
- Identifying code smells
- Ensuring compliance with Rails conventions
- Reviewing architecture decisions
- Assessing test coverage
- Evaluating API design
- Checking database migration safety

## Do not use this skill when

- Writing new code (use rails-help)
- The codebase doesn't follow Rails conventions
- Immediate deployment is required without review
- The change is a simple typo or documentation fix

## Prerequisites

- Understanding of Rails conventions and best practices
- Familiarity with SOLID principles
- Knowledge of common security vulnerabilities
- Understanding of database performance
- Experience with testing frameworks

## Core Concepts

### Code Review Goals

1. **Catch bugs early**: Find issues before they reach production
2. **Improve code quality**: Ensure maintainable, readable code
3. **Share knowledge**: Learn from each other
4. **Enforce standards**: Maintain consistency
5. **Enhance security**: Identify vulnerabilities
6. **Optimize performance**: Prevent performance regressions

### Types of Code Review

1. **Pre-commit review**: Before code is merged
2. **Post-commit review**: After deployment (for learning)
3. **Pair programming**: Real-time review
4. **Automated review**: Linting, static analysis
5. **Security review**: Focused on vulnerabilities
6. **Performance review**: Focused on optimization

## Comprehensive Review Checklist

### 1. Code Quality and Style

#### Rails Conventions

```ruby
# Good: Follows Rails naming conventions
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    if @order.save
      redirect_to @order
    else
      render :new
    end
  end

  private

  def order_params
    params.require(:order).permit(:total, :status)
  end
end

# Bad: Doesn't follow conventions
class OrdersController < ApplicationController
  def Create # Should be lowercase
    Order1 = Order.new(params[:order]) # No strong parameters
    if Order1.save
      redirect_to "/orders/#{Order1.id}" # Use path helpers
    end
  end
end
```

**Review Points:**
- [ ] Class and method names follow Rails conventions
- [ ] Strong parameters used for mass assignment
- [ ] Path helpers used instead of hardcoded paths
- [ ] Proper use of before_action callbacks
- [ ] Controllers are thin (business logic in models/services)

#### Code Readability

```ruby
# Good: Clear and readable
def eligible_for_discount?(user)
  user.premium? && user.orders.count >= 5 && !user.has_active_discount?
end

# Bad: Hard to understand
def elig?(u)
  u.prem? && u.orders.count >= 5 && !u.has_act_disc?
end
```

**Review Points:**
- [ ] Descriptive variable and method names
- [ ] Methods are short (< 10 lines ideally)
- [ ] Single responsibility per method
- [ ] Complex logic is commented
- [ ] No magic numbers (use constants)

#### DRY Principle

```ruby
# Good: DRY code
class User < ApplicationRecord
  NOTIFICATION_TYPES = %w[email sms push].freeze

  NOTIFICATION_TYPES.each do |type|
    define_method("send_#{type}_notification") do |message|
      NotificationService.send(type: type, user: self, message: message)
    end
  end
end

# Bad: Repetitive code
class User < ApplicationRecord
  def send_email_notification(message)
    NotificationService.send(type: 'email', user: self, message: message)
  end

  def send_sms_notification(message)
    NotificationService.send(type: 'sms', user: self, message: message)
  end

  def send_push_notification(message)
    NotificationService.send(type: 'push', user: self, message: message)
  end
end
```

**Review Points:**
- [ ] No duplicate code
- [ ] Shared logic extracted to methods/modules
- [ ] Reusable components identified
- [ ] Common patterns abstracted

### 2. Testing and Quality Assurance

#### Test Coverage

```ruby
# Good: Comprehensive tests
RSpec.describe Orders::CreateService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:params) { { total: 100, items: items_attributes } }

    context 'with valid params' do
      it 'creates an order' do
        expect { service.call }.to change(Order, :count).by(1)
      end

      it 'sends confirmation email' do
        expect(OrderMailer).to receive(:confirmation).and_call_original
        service.call
      end

      it 'returns success result' do
        result = service.call
        expect(result).to be_success
      end
    end

    context 'with invalid params' do
      let(:params) { { total: -1 } }

      it 'does not create an order' do
        expect { service.call }.not_to change(Order, :count)
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
      end
    end

    context 'when payment fails' do
      before do
        allow(PaymentService).to receive(:charge).and_raise(PaymentError)
      end

      it 'rolls back the transaction' do
        expect { service.call }.not_to change(Order, :count)
      end
    end
  end
end
```

**Review Points:**
- [ ] All new code has tests
- [ ] Happy path tested
- [ ] Edge cases covered
- [ ] Error handling tested
- [ ] Test descriptions are clear
- [ ] Tests use factories, not fixtures
- [ ] No ENV mutation in tests
- [ ] Tests are isolated and independent

#### Test Quality

```ruby
# Good: Clear, focused test
it 'sends welcome email after user registration' do
  user = create(:user)
  expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
  expect(ActionMailer::Base.deliveries.last.subject).to eq('Welcome!')
end

# Bad: Testing too much at once
it 'creates user and sends email and updates analytics' do
  user = create(:user)
  expect(user).to be_persisted
  expect(ActionMailer::Base.deliveries.count).to eq(1)
  expect(Analytics).to have_received(:track)
  expect(user.status).to eq('active')
end
```

**Review Points:**
- [ ] One assertion per test (or closely related assertions)
- [ ] Test names describe behavior, not implementation
- [ ] Proper use of contexts for different scenarios
- [ ] Appropriate use of let/let!/before blocks
- [ ] No brittle tests (no sleep, no excessive stubbing)

### 3. Security Review

#### SQL Injection Prevention

```ruby
# Good: Parameterized queries
User.where("name = ? AND status = ?", params[:name], params[:status])

# Bad: String interpolation
User.where("name = '#{params[:name]}'") # SQL injection vulnerability!
```

**Review Points:**
- [ ] No string interpolation in SQL queries
- [ ] All user input sanitized
- [ ] ActiveRecord query methods used properly
- [ ] Raw SQL avoided or properly parameterized

#### Mass Assignment Protection

```ruby
# Good: Strong parameters
def user_params
  params.require(:user).permit(:email, :name)
end

def create
  @user = User.new(user_params)
  @user.save
end

# Bad: Unfiltered params
def create
  @user = User.new(params[:user]) # Can set any attribute!
  @user.save
end
```

**Review Points:**
- [ ] Strong parameters used everywhere
- [ ] Only intended attributes permitted
- [ ] Admin-only attributes protected
- [ ] Nested attributes properly permitted

#### Authentication and Authorization

```ruby
# Good: Authorization check
class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:edit, :update, :destroy]

  def edit
    authorize @post # Using Pundit or similar
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id]) # Scoped to current user
  end
end

# Bad: No authorization
class PostsController < ApplicationController
  def edit
    @post = Post.find(params[:id]) # Can access anyone's post!
  end
end
```

**Review Points:**
- [ ] Authentication required where needed
- [ ] Authorization checks in place
- [ ] Resources scoped to current user
- [ ] Admin actions properly protected
- [ ] Session management secure
- [ ] Password requirements enforced

#### XSS Prevention

```erb
<!-- Good: Escaped output -->
<p><%= @user.bio %></p>

<!-- Bad: Raw HTML -->
<p><%== @user.bio %></p> <!-- XSS vulnerability! -->

<!-- Good: Sanitize if HTML needed -->
<p><%= sanitize @user.bio, tags: %w[b i u], attributes: %w[href] %></p>
```

**Review Points:**
- [ ] User input escaped by default
- [ ] `raw` and `html_safe` used sparingly
- [ ] Content sanitized when HTML is needed
- [ ] JavaScript injection prevented

#### Sensitive Data Exposure

```ruby
# Good: Sensitive data filtered
class User < ApplicationRecord
  def to_json(options = {})
    super(options.merge(except: [:password_digest, :api_token]))
  end
end

# Bad: Exposing sensitive data
class User < ApplicationRecord
  # Default to_json includes password_digest!
end
```

**Review Points:**
- [ ] Passwords never stored in plain text
- [ ] API keys/secrets in environment variables
- [ ] Sensitive data not logged
- [ ] Credentials encrypted at rest
- [ ] HTTPS enforced in production

### 4. Performance Review

#### N+1 Queries

```ruby
# Good: Eager loading
def index
  @posts = Post.includes(:user, :comments).all
end

# Bad: N+1 queries
def index
  @posts = Post.all # Then in view: @posts.each { |p| p.user.name }
end
```

**Review Points:**
- [ ] Eager loading used where appropriate
- [ ] No N+1 queries (check with Bullet gem)
- [ ] Database indexes exist for queried columns
- [ ] select used to limit loaded columns
- [ ] Queries optimized (check EXPLAIN)

#### Database Queries

```ruby
# Good: Efficient query
User.active.where(created_at: 1.month.ago..).count

# Bad: Loading all records
User.active.where(created_at: 1.month.ago..).to_a.count # Loads all!
```

**Review Points:**
- [ ] count/exists? used instead of loading records
- [ ] Queries use database-level operations
- [ ] Batch processing for large datasets
- [ ] Background jobs for slow operations
- [ ] Appropriate use of caching

#### Caching Strategy

```ruby
# Good: Caching expensive operations
def trending_posts
  Rails.cache.fetch('trending_posts', expires_in: 1.hour) do
    Post.published
        .where('created_at > ?', 1.week.ago)
        .joins(:likes)
        .group('posts.id')
        .order('COUNT(likes.id) DESC')
        .limit(10)
  end
end

# Bad: No caching
def trending_posts
  Post.published
      .where('created_at > ?', 1.week.ago)
      .joins(:likes)
      .group('posts.id')
      .order('COUNT(likes.id) DESC')
      .limit(10)
end
```

**Review Points:**
- [ ] Expensive operations cached
- [ ] Cache invalidation strategy in place
- [ ] Fragment caching used in views
- [ ] HTTP caching headers set
- [ ] Counter caches used for associations

### 5. Database Migrations

#### Safe Migrations

```ruby
# Good: Safe migration
class AddEmailToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email, :string
    add_index :users, :email, algorithm: :concurrently
  end
end

# Bad: Unsafe migration (locks table)
class AddIndexToUsers < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :email # Locks table on large dataset!
  end
end

# Good: Using disable_ddl_transaction for concurrent index
class AddIndexToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :users, :email, algorithm: :concurrently
  end
end
```

**Review Points:**
- [ ] Migrations are reversible
- [ ] No data changes in structure migrations
- [ ] Indexes created concurrently on large tables
- [ ] Foreign keys added where appropriate
- [ ] Default values set appropriately
- [ ] NOT NULL constraints added carefully

#### Migration Best Practices

```ruby
# Good: Separate data and structure changes
# Migration 1: Add column with default
class AddStatusToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :status, :string, default: 'pending', null: false
  end
end

# Migration 2 (later): Update data if needed
class BackfillOrderStatus < ActiveRecord::Migration[7.1]
  def up
    Order.where(paid_at: nil).update_all(status: 'pending')
    Order.where.not(paid_at: nil).update_all(status: 'completed')
  end

  def down
    # No-op or reverse if possible
  end
end

# Bad: Everything in one migration
class AddAndUpdateStatus < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :status, :string

    Order.all.each do |order| # Don't do this!
      order.update(status: order.paid? ? 'completed' : 'pending')
    end
  end
end
```

**Review Points:**
- [ ] Structure changes separate from data changes
- [ ] Migrations tested on production-size dataset
- [ ] Rollback strategy considered
- [ ] No model code in migrations (use SQL)
- [ ] Batch updates for large datasets

### 6. API Design Review

#### RESTful Design

```ruby
# Good: RESTful routes
resources :posts do
  resources :comments, only: [:index, :create, :destroy]
  member do
    post :publish
    post :unpublish
  end
end

# Bad: Non-RESTful
post '/posts/:id/do_publish'
post '/posts/:id/remove_post'
get '/posts/:id/get_comments'
```

**Review Points:**
- [ ] RESTful routes used
- [ ] HTTP verbs used correctly
- [ ] Nested resources limited (max 1-2 levels)
- [ ] Custom actions used sparingly
- [ ] API versioned properly

#### Response Format

```ruby
# Good: Consistent response format
def index
  @posts = Post.all

  render json: {
    data: PostBlueprint.render_as_hash(@posts),
    meta: {
      total: @posts.count,
      page: params[:page] || 1
    }
  }
end

# Bad: Inconsistent responses
def index
  render json: Post.all
end

def show
  render json: { post: @post, user: @post.user }
end
```

**Review Points:**
- [ ] Response format consistent across endpoints
- [ ] Proper HTTP status codes used
- [ ] Error responses standardized
- [ ] Pagination included in list endpoints
- [ ] API documentation updated

### 7. Error Handling

#### Comprehensive Error Handling

```ruby
# Good: Proper error handling
class OrdersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from PaymentError, with: :payment_failed

  def create
    @order = Orders::CreateService.call(user: current_user, params: order_params)

    if @order.success?
      render json: @order.value, status: :created
    else
      render json: { errors: @order.errors }, status: :unprocessable_entity
    end
  end

  private

  def not_found
    render json: { error: 'Order not found' }, status: :not_found
  end

  def payment_failed(exception)
    render json: { error: exception.message }, status: :payment_required
  end
end

# Bad: No error handling
def create
  @order = Order.create!(order_params) # Raises on failure
  render json: @order
end
```

**Review Points:**
- [ ] Exceptions handled appropriately
- [ ] User-friendly error messages
- [ ] Errors logged with context
- [ ] Failed operations rolled back
- [ ] External service failures handled

### 8. Code Architecture

#### Service Objects

```ruby
# Good: Focused service object
class Orders::CreateService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    ApplicationRecord.transaction do
      create_order
      process_payment
      send_confirmation
      Result.success(@order)
    end
  rescue => e
    Result.failure(e.message)
  end

  private

  # Implementation
end

# Bad: God object
class OrderService
  def create_order(...)
  end

  def update_order(...)
  end

  def cancel_order(...)
  end

  def process_payment(...)
  end

  def generate_invoice(...)
  end

  # Too many responsibilities!
end
```

**Review Points:**
- [ ] Single Responsibility Principle followed
- [ ] Service objects focused on one task
- [ ] Business logic extracted from controllers
- [ ] Domain objects properly modeled
- [ ] Dependencies injected, not hardcoded

## Code Review Process

### 1. Before Requesting Review

**Developer Checklist:**
- [ ] All tests pass locally
- [ ] Linter run and issues fixed
- [ ] Self-review completed
- [ ] PR description is clear and complete
- [ ] Screenshots provided for UI changes
- [ ] Breaking changes documented
- [ ] Migration plan included if needed

### 2. Review Best Practices

**For Reviewers:**
- Be kind and constructive
- Ask questions rather than making demands
- Explain the "why" behind suggestions
- Approve if blocking issues are resolved
- Distinguish between blocking and non-blocking issues
- Review promptly (within 24 hours)

**Example Comments:**

```markdown
# Good: Constructive feedback
💡 Consider extracting this query to a scope for reusability:
`scope :active, -> { where(status: 'active') }`
This would make it easier to test and reuse.

# Bad: Demanding tone
This is wrong. You should use a scope.

# Good: Asking questions
❓ Have you considered the case where the user is nil?
This might raise an error.

# Bad: Unclear
This might break.

# Good: Approving with suggestions
✅ LGTM! One suggestion: consider adding a database index on
`users.email` for better query performance. Not blocking.

# Bad: Nitpicking
The indentation is off by one space on line 42.
```

### 3. Responding to Reviews

**For Authors:**
- Thank reviewers for their time
- Address all comments
- Explain decisions when pushing back
- Ask for clarification if confused
- Update PR based on feedback
- Mark resolved comments

## Automated Review Tools

### RuboCop

```ruby
# .rubocop.yml
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/*'
    - 'vendor/**/*'
    - 'bin/**/*'

Style/Documentation:
  Enabled: false

Metrics/MethodLength:
  Max: 10
  Exclude:
    - 'spec/**/*'

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'
```

### Brakeman (Security Scanner)

```bash
# Run security scan
brakeman -A -q

# In CI pipeline
brakeman --exit-on-warn --no-pager
```

### SimpleCov (Test Coverage)

```ruby
# spec/rails_helper.rb
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  minimum_coverage 90
end
```

## Review Checklist Template

```markdown
## Code Review Checklist

### Functionality
- [ ] Code works as described
- [ ] All acceptance criteria met
- [ ] Edge cases handled
- [ ] Error handling in place

### Tests
- [ ] All tests pass
- [ ] New code is tested
- [ ] Tests are clear and focused
- [ ] Coverage is adequate

### Security
- [ ] No SQL injection vulnerabilities
- [ ] Strong parameters used
- [ ] Authorization checks in place
- [ ] Sensitive data protected

### Performance
- [ ] No N+1 queries
- [ ] Indexes added where needed
- [ ] Caching used appropriately
- [ ] Background jobs for slow operations

### Code Quality
- [ ] Code is readable and maintainable
- [ ] Follows Rails conventions
- [ ] No code smells
- [ ] Proper abstractions

### Database
- [ ] Migrations are safe
- [ ] Migrations are reversible
- [ ] Indexes created concurrently

### Documentation
- [ ] PR description is clear
- [ ] Code is self-documenting
- [ ] Complex logic is commented
- [ ] API changes documented

## Conclusion

Thorough code reviews improve code quality, catch bugs early, and share knowledge across the team. Be constructive, thorough, and kind in your reviews.
