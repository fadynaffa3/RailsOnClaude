---
name: rails-refactoring-guide
description: Service to PORO patterns, fat model extraction, callback refactoring, code smell elimination for Rails applications. Extract business logic, eliminate code smells, refactor callbacks, apply design patterns.
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - refactoring
  - poro
  - service-objects
  - design-patterns
  - code-smells
  - clean-code
dependencies:
  - rails >= 7.0
---

# Rails Refactoring Guide

A comprehensive guide for refactoring Ruby on Rails applications to eliminate code smells, extract business logic into POROs (Plain Old Ruby Objects), refactor fat models, eliminate callback hell, and apply SOLID principles. This skill helps transform legacy codebases into maintainable, testable, and scalable applications.

## Use this skill when

- Refactoring fat models with too much business logic
- Extracting business logic from controllers
- Eliminating callback hell and complex ActiveRecord callbacks
- Converting service objects to POROs
- Identifying and eliminating code smells
- Applying SOLID principles to Rails code
- Improving code maintainability and testability
- Simplifying complex conditional logic
- Removing duplication across models and controllers
- Preparing legacy code for new features
- Reducing coupling between components
- Making code more modular and composable
- Improving test coverage through better design
- Refactoring toward domain-driven design
- Eliminating God objects and feature envy

## Do not use this skill when

- Code is already well-structured and follows SOLID principles
- Writing new code from scratch (use rails-help)
- Performance optimization is the primary goal (use rails-performance-optimizer)
- Working with database queries (use rails-db-optimizer)
- The refactoring would break existing functionality without tests
- Time constraints prevent proper testing
- The code works fine and doesn't need changes

## Prerequisites

- Rails 7.0+ installed
- Understanding of SOLID principles
- Familiarity with design patterns
- Knowledge of Ruby idioms and best practices
- Existing test coverage (or willingness to write tests first)
- Understanding of the current codebase behavior

## Core Concepts

### SOLID Principles in Rails

1. **Single Responsibility Principle (SRP)**: Each class should have one reason to change
2. **Open/Closed Principle (OCP)**: Open for extension, closed for modification
3. **Liskov Substitution Principle (LSP)**: Subtypes must be substitutable for their base types
4. **Interface Segregation Principle (ISP)**: Many specific interfaces are better than one general interface
5. **Dependency Inversion Principle (DIP)**: Depend on abstractions, not concretions

### Common Code Smells in Rails

- **Fat Models**: Models with too many methods and responsibilities
- **Fat Controllers**: Controllers with business logic
- **Callback Hell**: Complex chains of ActiveRecord callbacks
- **God Objects**: Classes that know too much or do too much
- **Feature Envy**: Methods that use another object's data more than their own
- **Long Methods**: Methods that are too long to understand
- **Long Parameter Lists**: Methods with too many parameters
- **Primitive Obsession**: Using primitives instead of small objects
- **Data Clumps**: Same group of data appearing together
- **Divergent Change**: One class changing for multiple reasons
- **Shotgun Surgery**: One change requires many small changes

### Refactoring Strategies

1. **Extract Service Objects**: Move complex operations to dedicated service classes
2. **Extract POROs**: Create domain objects for business logic
3. **Extract Query Objects**: Isolate complex queries
4. **Extract Form Objects**: Handle form logic separately
5. **Extract Decorators/Presenters**: Separate view logic
6. **Extract Policy Objects**: Isolate authorization logic
7. **Replace Callbacks with Service Objects**: Make side effects explicit
8. **Extract Value Objects**: Create immutable objects for business concepts

## Step-by-Step Implementation

### Step 1: Identify Code Smells

#### Fat Model Example

```ruby
# app/models/user.rb (BAD)
class User < ApplicationRecord
  has_many :posts
  has_many :orders
  has_many :subscriptions

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, format: { with: /\A[a-zA-Z0-9_]+\z/ }

  before_create :generate_api_token
  before_save :normalize_email
  after_create :send_welcome_email
  after_create :create_default_profile
  after_create :notify_admin
  after_update :sync_to_crm, if: :email_changed?
  after_commit :update_search_index

  # Authentication
  def authenticate(password)
    BCrypt::Password.new(password_digest).is_password?(password)
  end

  def generate_reset_token
    self.reset_token = SecureRandom.urlsafe_base64
    self.reset_token_expires_at = 24.hours.from_now
    save!
  end

  # Email notifications
  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end

  def send_notification(message)
    UserMailer.notification(self, message).deliver_later
    SlackNotifier.notify(self, message) if slack_enabled?
  end

  # Subscription logic
  def subscribe_to(plan)
    subscriptions.create!(plan: plan, starts_at: Time.current)
    charge_subscription_fee(plan)
    update_subscription_status
  end

  def cancel_subscription
    current_subscription.update!(ends_at: Time.current)
    process_refund if eligible_for_refund?
    send_cancellation_email
  end

  def eligible_for_refund?
    current_subscription.created_at > 7.days.ago
  end

  # Analytics
  def calculate_lifetime_value
    orders.sum(:total)
  end

  def activity_score
    (posts.count * 10) + (orders.count * 50) + (subscriptions.count * 100)
  end

  # CRM sync
  def sync_to_crm
    CrmClient.new.update_contact(
      email: email,
      name: full_name,
      subscription_status: subscription_status
    )
  rescue => e
    Rails.logger.error("CRM sync failed: #{e.message}")
  end

  # Search
  def update_search_index
    SearchIndexer.index_user(self)
  end

  # Helpers
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def subscription_status
    current_subscription&.active? ? 'active' : 'inactive'
  end

  def current_subscription
    subscriptions.active.first
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end

  def normalize_email
    self.email = email.downcase.strip
  end

  def charge_subscription_fee(plan)
    PaymentProcessor.charge(
      user: self,
      amount: plan.price,
      description: "Subscription to #{plan.name}"
    )
  end

  def update_subscription_status
    update!(subscription_status: 'active')
  end

  def process_refund
    PaymentProcessor.refund(current_subscription.charge_id)
  end

  def send_cancellation_email
    UserMailer.subscription_cancelled(self).deliver_later
  end

  def slack_enabled?
    slack_webhook_url.present?
  end

  def notify_admin
    AdminMailer.new_user_registered(self).deliver_later
  end
end
```

**Problems:**
- 300+ lines in one model
- Multiple responsibilities (auth, subscriptions, notifications, CRM, search)
- Complex callback chains
- Business logic mixed with persistence
- Hard to test individual pieces
- Violates Single Responsibility Principle

### Step 2: Extract Service Objects

#### Refactor Subscription Logic

```ruby
# app/services/subscriptions/create_service.rb
module Subscriptions
  class CreateService
    def initialize(user:, plan:)
      @user = user
      @plan = plan
    end

    def call
      return failure("User already has active subscription") if active_subscription?

      ApplicationRecord.transaction do
        subscription = create_subscription
        charge_user(subscription)
        update_user_status
        send_notifications
        success(subscription)
      end
    rescue PaymentError => e
      failure(e.message)
    end

    private

    attr_reader :user, :plan

    def active_subscription?
      user.subscriptions.active.exists?
    end

    def create_subscription
      user.subscriptions.create!(
        plan: plan,
        starts_at: Time.current,
        status: 'active'
      )
    end

    def charge_user(subscription)
      charge = PaymentProcessor.charge(
        user: user,
        amount: plan.price,
        description: "Subscription to #{plan.name}"
      )

      subscription.update!(charge_id: charge.id)
    end

    def update_user_status
      user.update!(subscription_status: 'active')
    end

    def send_notifications
      UserMailer.subscription_created(user, plan).deliver_later
    end

    def success(subscription)
      Result.success(subscription)
    end

    def failure(message)
      Result.failure(message)
    end
  end
end
```

```ruby
# app/services/subscriptions/cancel_service.rb
module Subscriptions
  class CancelService
    def initialize(subscription:)
      @subscription = subscription
      @user = subscription.user
    end

    def call
      return failure("Subscription already cancelled") if subscription.cancelled?

      ApplicationRecord.transaction do
        cancel_subscription
        process_refund if eligible_for_refund?
        send_notifications
        success
      end
    end

    private

    attr_reader :subscription, :user

    def cancel_subscription
      subscription.update!(
        ends_at: Time.current,
        status: 'cancelled'
      )
    end

    def eligible_for_refund?
      Subscriptions::RefundPolicy.new(subscription).eligible?
    end

    def process_refund
      Subscriptions::ProcessRefundService.call(subscription: subscription)
    end

    def send_notifications
      UserMailer.subscription_cancelled(user).deliver_later
    end

    def success
      Result.success
    end

    def failure(message)
      Result.failure(message)
    end
  end
end
```

```ruby
# app/services/subscriptions/refund_policy.rb
module Subscriptions
  class RefundPolicy
    REFUND_WINDOW = 7.days

    def initialize(subscription)
      @subscription = subscription
    end

    def eligible?
      within_refund_window? && has_charge?
    end

    private

    attr_reader :subscription

    def within_refund_window?
      subscription.created_at > REFUND_WINDOW.ago
    end

    def has_charge?
      subscription.charge_id.present?
    end
  end
end
```

```ruby
# app/services/result.rb
class Result
  attr_reader :value, :error

  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  def initialize(success:, value: nil, error: nil)
    @success = success
    @value = value
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
```

#### Updated Model

```ruby
# app/models/user.rb (BETTER)
class User < ApplicationRecord
  has_many :posts
  has_many :orders
  has_many :subscriptions

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, format: { with: /\A[a-zA-Z0-9_]+\z/ }

  before_create :generate_api_token
  before_save :normalize_email

  def subscribe_to(plan)
    Subscriptions::CreateService.call(user: self, plan: plan)
  end

  def cancel_subscription
    subscription = subscriptions.active.first
    return Result.failure("No active subscription") unless subscription

    Subscriptions::CancelService.call(subscription: subscription)
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

### Step 3: Eliminate Callback Hell

#### Bad Example with Callbacks

```ruby
# app/models/order.rb (BAD)
class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items

  before_validation :calculate_total
  before_create :generate_order_number
  after_create :send_confirmation_email
  after_create :create_invoice
  after_create :update_inventory
  after_create :notify_warehouse
  after_create :update_analytics
  after_update :sync_to_accounting, if: :saved_change_to_status?
  after_commit :notify_customer, on: [:create, :update]

  private

  def calculate_total
    self.total = line_items.sum(&:price)
  end

  def generate_order_number
    self.order_number = "ORD-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end

  def send_confirmation_email
    OrderMailer.confirmation(self).deliver_later
  end

  def create_invoice
    Invoice.create!(order: self, amount: total)
  end

  def update_inventory
    line_items.each do |item|
      item.product.decrement!(:stock, item.quantity)
    end
  end

  def notify_warehouse
    WarehouseNotifier.new_order(self)
  end

  def update_analytics
    AnalyticsTracker.track('order_created', order_id: id)
  end

  def sync_to_accounting
    AccountingSync.sync_order(self)
  end

  def notify_customer
    CustomerNotifier.order_updated(self)
  end
end
```

**Problems:**
- 9 callbacks doing different things
- Side effects hidden in model
- Hard to test individual operations
- Callbacks fire even in tests
- Order of operations unclear
- Difficult to skip certain operations

#### Good Example with Service Object

```ruby
# app/models/order.rb (GOOD)
class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items

  before_validation :calculate_total
  before_create :generate_order_number

  def calculate_total
    self.total = line_items.sum(&:price)
  end

  private

  def generate_order_number
    self.order_number = "ORD-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
  end
end
```

```ruby
# app/services/orders/create_service.rb
module Orders
  class CreateService
    def initialize(user:, line_items_attributes:)
      @user = user
      @line_items_attributes = line_items_attributes
    end

    def call
      ApplicationRecord.transaction do
        order = create_order
        create_line_items(order)
        process_order(order)
        Result.success(order)
      end
    rescue => e
      Result.failure(e.message)
    end

    private

    attr_reader :user, :line_items_attributes

    def create_order
      user.orders.create!
    end

    def create_line_items(order)
      line_items_attributes.each do |attrs|
        order.line_items.create!(attrs)
      end
      order.reload # Recalculate total
    end

    def process_order(order)
      Orders::ProcessService.call(order: order)
    end
  end
end
```

```ruby
# app/services/orders/process_service.rb
module Orders
  class ProcessService
    def initialize(order:)
      @order = order
    end

    def call
      update_inventory
      create_invoice
      send_notifications
      update_analytics
      Result.success
    end

    private

    attr_reader :order

    def update_inventory
      Inventory::UpdateService.call(order: order)
    end

    def create_invoice
      Invoices::CreateService.call(order: order)
    end

    def send_notifications
      notify_customer
      notify_warehouse
    end

    def notify_customer
      OrderMailer.confirmation(order).deliver_later
    end

    def notify_warehouse
      WarehouseNotifier.new_order(order)
    end

    def update_analytics
      AnalyticsTracker.track('order_created', order_id: order.id)
    end
  end
end
```

### Step 4: Extract Query Objects

#### Bad Example

```ruby
# app/models/post.rb (BAD)
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }

  def self.popular_in_timeframe(start_date, end_date)
    published
      .where(created_at: start_date..end_date)
      .joins(:comments)
      .group('posts.id')
      .having('COUNT(comments.id) > ?', 10)
      .order('COUNT(comments.id) DESC')
  end

  def self.trending
    published
      .where('created_at > ?', 7.days.ago)
      .left_joins(:likes, :comments)
      .select(
        'posts.*',
        'COUNT(DISTINCT likes.id) as likes_count',
        'COUNT(DISTINCT comments.id) as comments_count'
      )
      .group('posts.id')
      .having('COUNT(DISTINCT likes.id) + COUNT(DISTINCT comments.id) > ?', 50)
      .order('(COUNT(DISTINCT likes.id) + COUNT(DISTINCT comments.id)) DESC')
  end

  def self.by_author_with_engagement(author_id)
    where(user_id: author_id)
      .published
      .left_joins(:likes, :comments, :shares)
      .select(
        'posts.*',
        'COUNT(DISTINCT likes.id) as likes_count',
        'COUNT(DISTINCT comments.id) as comments_count',
        'COUNT(DISTINCT shares.id) as shares_count'
      )
      .group('posts.id')
  end
end
```

#### Good Example with Query Objects

```ruby
# app/models/post.rb (GOOD)
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
end
```

```ruby
# app/queries/posts/popular_query.rb
module Posts
  class PopularQuery
    DEFAULT_COMMENT_THRESHOLD = 10

    def initialize(relation = Post.all)
      @relation = relation
    end

    def call(start_date:, end_date:, comment_threshold: DEFAULT_COMMENT_THRESHOLD)
      relation
        .published
        .where(created_at: start_date..end_date)
        .joins(:comments)
        .group('posts.id')
        .having('COUNT(comments.id) > ?', comment_threshold)
        .order('COUNT(comments.id) DESC')
    end

    private

    attr_reader :relation
  end
end
```

```ruby
# app/queries/posts/trending_query.rb
module Posts
  class TrendingQuery
    TRENDING_WINDOW = 7.days
    ENGAGEMENT_THRESHOLD = 50

    def initialize(relation = Post.all)
      @relation = relation
    end

    def call(days_back: TRENDING_WINDOW, threshold: ENGAGEMENT_THRESHOLD)
      relation
        .published
        .where('created_at > ?', days_back.ago)
        .left_joins(:likes, :comments)
        .select(
          'posts.*',
          'COUNT(DISTINCT likes.id) as likes_count',
          'COUNT(DISTINCT comments.id) as comments_count',
          engagement_score_sql
        )
        .group('posts.id')
        .having("#{engagement_score_sql} > ?", threshold)
        .order("#{engagement_score_sql} DESC")
    end

    private

    attr_reader :relation

    def engagement_score_sql
      '(COUNT(DISTINCT likes.id) + COUNT(DISTINCT comments.id))'
    end
  end
end
```

```ruby
# app/queries/posts/author_engagement_query.rb
module Posts
  class AuthorEngagementQuery
    def initialize(relation = Post.all)
      @relation = relation
    end

    def call(author_id:)
      relation
        .where(user_id: author_id)
        .published
        .left_joins(:likes, :comments, :shares)
        .select(
          'posts.*',
          'COUNT(DISTINCT likes.id) as likes_count',
          'COUNT(DISTINCT comments.id) as comments_count',
          'COUNT(DISTINCT shares.id) as shares_count'
        )
        .group('posts.id')
    end

    private

    attr_reader :relation
  end
end
```

#### Usage

```ruby
# In controller
def popular
  @posts = Posts::PopularQuery.new.call(
    start_date: 1.month.ago,
    end_date: Time.current,
    comment_threshold: 20
  )
end

def trending
  @posts = Posts::TrendingQuery.new.call(days_back: 3.days)
end

def author_posts
  @posts = Posts::AuthorEngagementQuery.new.call(author_id: params[:author_id])
end
```

### Step 5: Extract Form Objects

#### Bad Example

```ruby
# app/controllers/registrations_controller.rb (BAD)
class RegistrationsController < ApplicationController
  def create
    @user = User.new(user_params)
    @user.email = @user.email.downcase.strip
    @user.username = @user.username.strip

    if @user.valid?
      ApplicationRecord.transaction do
        @user.save!
        @profile = @user.build_profile(profile_params)
        @profile.save!

        @subscription = @user.subscriptions.build(
          plan_id: params[:plan_id],
          starts_at: Time.current
        )
        @subscription.save!

        UserMailer.welcome(@user).deliver_later
        AdminMailer.new_registration(@user).deliver_later

        redirect_to dashboard_path, notice: 'Registration successful!'
      end
    else
      render :new
    end
  rescue => e
    flash.now[:alert] = "Registration failed: #{e.message}"
    render :new
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation)
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :bio)
  end
end
```

#### Good Example with Form Object

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :username, :string
  attribute :password, :string
  attribute :password_confirmation, :string
  attribute :first_name, :string
  attribute :last_name, :string
  attribute :bio, :string
  attribute :plan_id, :integer

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, length: { minimum: 3 }
  validates :password, presence: true, length: { minimum: 8 }
  validates :password_confirmation, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :plan_id, presence: true

  validate :passwords_match
  validate :email_uniqueness
  validate :username_uniqueness

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      create_user
      create_profile
      create_subscription
      send_notifications
    end

    true
  rescue => e
    errors.add(:base, e.message)
    false
  end

  private

  attr_reader :user

  def create_user
    @user = User.create!(
      email: normalized_email,
      username: normalized_username,
      password: password,
      password_confirmation: password_confirmation
    )
  end

  def create_profile
    user.create_profile!(
      first_name: first_name,
      last_name: last_name,
      bio: bio
    )
  end

  def create_subscription
    user.subscriptions.create!(
      plan_id: plan_id,
      starts_at: Time.current,
      status: 'active'
    )
  end

  def send_notifications
    UserMailer.welcome(user).deliver_later
    AdminMailer.new_registration(user).deliver_later
  end

  def normalized_email
    email.downcase.strip
  end

  def normalized_username
    username.strip
  end

  def passwords_match
    errors.add(:password_confirmation, "doesn't match password") if password != password_confirmation
  end

  def email_uniqueness
    errors.add(:email, 'has already been taken') if User.exists?(email: normalized_email)
  end

  def username_uniqueness
    errors.add(:username, 'has already been taken') if User.exists?(username: normalized_username)
  end
end
```

```ruby
# app/controllers/registrations_controller.rb (GOOD)
class RegistrationsController < ApplicationController
  def new
    @registration_form = RegistrationForm.new
  end

  def create
    @registration_form = RegistrationForm.new(registration_params)

    if @registration_form.save
      redirect_to dashboard_path, notice: 'Registration successful!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration_form).permit(
      :email,
      :username,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :bio,
      :plan_id
    )
  end
end
```

### Step 6: Extract Value Objects

#### Bad Example

```ruby
# app/models/product.rb (BAD)
class Product < ApplicationRecord
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR GBP] }

  def price_display
    case currency
    when 'USD'
      "$#{price_cents / 100.0}"
    when 'EUR'
      "€#{price_cents / 100.0}"
    when 'GBP'
      "£#{price_cents / 100.0}"
    end
  end

  def discounted_price(percentage)
    discounted_cents = price_cents * (1 - percentage / 100.0)
    {
      cents: discounted_cents.to_i,
      currency: currency
    }
  end

  def price_in_currency(target_currency)
    rate = ExchangeRate.find_by!(from: currency, to: target_currency).rate
    converted_cents = (price_cents * rate).to_i
    {
      cents: converted_cents,
      currency: target_currency
    }
  end
end
```

#### Good Example with Value Object

```ruby
# app/value_objects/money.rb
class Money
  include Comparable

  CURRENCY_SYMBOLS = {
    'USD' => '$',
    'EUR' => '€',
    'GBP' => '£'
  }.freeze

  attr_reader :cents, :currency

  def initialize(cents, currency = 'USD')
    @cents = cents.to_i
    @currency = currency.to_s.upcase

    validate!
    freeze
  end

  def self.from_amount(amount, currency = 'USD')
    new((amount * 100).to_i, currency)
  end

  def amount
    cents / 100.0
  end

  def display
    "#{currency_symbol}#{format('%.2f', amount)}"
  end

  def +(other)
    ensure_same_currency!(other)
    self.class.new(cents + other.cents, currency)
  end

  def -(other)
    ensure_same_currency!(other)
    self.class.new(cents - other.cents, currency)
  end

  def *(factor)
    self.class.new((cents * factor).to_i, currency)
  end

  def /(divisor)
    self.class.new((cents / divisor).to_i, currency)
  end

  def discount(percentage)
    multiplier = 1 - (percentage / 100.0)
    self * multiplier
  end

  def convert_to(target_currency)
    return self if currency == target_currency

    rate = ExchangeRate.find_by!(from: currency, to: target_currency).rate
    converted_cents = (cents * rate).to_i

    self.class.new(converted_cents, target_currency)
  end

  def <=>(other)
    ensure_same_currency!(other)
    cents <=> other.cents
  end

  def zero?
    cents.zero?
  end

  def positive?
    cents.positive?
  end

  def negative?
    cents.negative?
  end

  def to_s
    display
  end

  def to_h
    { cents: cents, currency: currency }
  end

  def as_json(options = nil)
    to_h
  end

  private

  def currency_symbol
    CURRENCY_SYMBOLS.fetch(currency, currency)
  end

  def validate!
    raise ArgumentError, 'Cents must be an integer' unless cents.is_a?(Integer)
    raise ArgumentError, 'Currency must be a string' unless currency.is_a?(String)
    raise ArgumentError, "Invalid currency: #{currency}" unless CURRENCY_SYMBOLS.key?(currency)
  end

  def ensure_same_currency!(other)
    raise ArgumentError, "Cannot operate on different currencies: #{currency} and #{other.currency}" if currency != other.currency
  end
end
```

```ruby
# app/models/product.rb (GOOD)
class Product < ApplicationRecord
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :price_currency, presence: true, inclusion: { in: Money::CURRENCY_SYMBOLS.keys }

  def price
    Money.new(price_cents, price_currency)
  end

  def price=(money)
    self.price_cents = money.cents
    self.price_currency = money.currency
  end

  def discounted_price(percentage)
    price.discount(percentage)
  end

  def price_in_currency(target_currency)
    price.convert_to(target_currency)
  end
end
```

### Step 7: Extract Decorators/Presenters

#### Bad Example

```ruby
# app/models/user.rb (BAD)
class User < ApplicationRecord
  def display_name
    full_name.present? ? full_name : username
  end

  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
    else
      "https://ui-avatars.com/api/?name=#{CGI.escape(display_name)}&size=200"
    end
  end

  def member_since
    created_at.strftime('%B %Y')
  end

  def status_badge
    case status
    when 'active'
      '<span class="badge badge-success">Active</span>'.html_safe
    when 'inactive'
      '<span class="badge badge-secondary">Inactive</span>'.html_safe
    when 'suspended'
      '<span class="badge badge-danger">Suspended</span>'.html_safe
    end
  end

  def post_count_display
    count = posts.count
    "#{count} #{count == 1 ? 'post' : 'posts'}"
  end

  def bio_preview
    bio.present? ? bio.truncate(100) : 'No bio provided'
  end
end
```

#### Good Example with Decorator

```ruby
# app/decorators/user_decorator.rb
class UserDecorator < SimpleDelegator
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context

  def display_name
    full_name.present? ? full_name : username
  end

  def avatar_url(size: 200)
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: false)
    else
      default_avatar_url(size)
    end
  end

  def member_since
    created_at.strftime('%B %Y')
  end

  def status_badge
    case status
    when 'active'
      badge('Active', 'success')
    when 'inactive'
      badge('Inactive', 'secondary')
    when 'suspended'
      badge('Suspended', 'danger')
    end
  end

  def post_count_display
    count = posts.count
    pluralize(count, 'post')
  end

  def bio_preview(length: 100)
    bio.present? ? bio.truncate(length) : 'No bio provided'
  end

  def profile_link
    link_to display_name, profile_path
  end

  def formatted_email
    mail_to email
  end

  private

  def badge(text, type)
    content_tag(:span, text, class: "badge badge-#{type}")
  end

  def default_avatar_url(size)
    "https://ui-avatars.com/api/?name=#{CGI.escape(display_name)}&size=#{size}"
  end

  def profile_path
    Rails.application.routes.url_helpers.user_path(__getobj__)
  end

  def pluralize(count, singular, plural = nil)
    "#{count} #{count == 1 ? singular : (plural || singular.pluralize)}"
  end
end
```

```ruby
# app/models/user.rb (GOOD)
class User < ApplicationRecord
  has_many :posts

  def decorate
    UserDecorator.new(self)
  end
end
```

```ruby
# In views
<%= @user.decorate.display_name %>
<%= image_tag @user.decorate.avatar_url(size: 150) %>
<%= @user.decorate.status_badge %>
<%= @user.decorate.post_count_display %>
<%= @user.decorate.bio_preview(length: 50) %>
```

### Step 8: Replace Conditional Logic with Polymorphism

#### Bad Example

```ruby
# app/models/notification.rb (BAD)
class Notification < ApplicationRecord
  TYPES = %w[email sms push slack].freeze

  validates :notification_type, inclusion: { in: TYPES }

  def deliver
    case notification_type
    when 'email'
      deliver_email
    when 'sms'
      deliver_sms
    when 'push'
      deliver_push
    when 'slack'
      deliver_slack
    end
  end

  private

  def deliver_email
    NotificationMailer.send_notification(recipient, message).deliver_later
  end

  def deliver_sms
    TwilioClient.send_sms(
      to: recipient_phone,
      body: message
    )
  end

  def deliver_push
    PushNotificationService.send(
      device_token: recipient_device_token,
      title: title,
      body: message
    )
  end

  def deliver_slack
    SlackClient.post_message(
      channel: recipient_slack_channel,
      text: message
    )
  end
end
```

#### Good Example with Polymorphism

```ruby
# app/models/notification.rb (GOOD)
class Notification < ApplicationRecord
  belongs_to :delivery_channel, polymorphic: true

  def deliver
    delivery_channel.deliver(self)
  end
end
```

```ruby
# app/models/notification_channels/email_channel.rb
module NotificationChannels
  class EmailChannel < ApplicationRecord
    has_many :notifications, as: :delivery_channel

    def deliver(notification)
      NotificationMailer.send_notification(
        email_address,
        notification.message
      ).deliver_later
    end
  end
end
```

```ruby
# app/models/notification_channels/sms_channel.rb
module NotificationChannels
  class SmsChannel < ApplicationRecord
    has_many :notifications, as: :delivery_channel

    def deliver(notification)
      TwilioClient.send_sms(
        to: phone_number,
        body: notification.message
      )
    end
  end
end
```

```ruby
# app/models/notification_channels/push_channel.rb
module NotificationChannels
  class PushChannel < ApplicationRecord
    has_many :notifications, as: :delivery_channel

    def deliver(notification)
      PushNotificationService.send(
        device_token: device_token,
        title: notification.title,
        body: notification.message
      )
    end
  end
end
```

```ruby
# app/models/notification_channels/slack_channel.rb
module NotificationChannels
  class SlackChannel < ApplicationRecord
    has_many :notifications, as: :delivery_channel

    def deliver(notification)
      SlackClient.post_message(
        channel: channel_name,
        text: notification.message
      )
    end
  end
end
```

### Step 9: Extract Policy Objects

#### Bad Example

```ruby
# app/models/post.rb (BAD)
class Post < ApplicationRecord
  belongs_to :user

  def can_edit?(current_user)
    return false unless current_user

    user_id == current_user.id ||
      current_user.admin? ||
      current_user.moderator?
  end

  def can_delete?(current_user)
    return false unless current_user

    user_id == current_user.id ||
      current_user.admin?
  end

  def can_publish?(current_user)
    return false unless current_user
    return false if published?

    user_id == current_user.id ||
      current_user.admin? ||
      current_user.editor?
  end

  def can_feature?(current_user)
    return false unless current_user

    current_user.admin? || current_user.editor?
  end
end
```

#### Good Example with Policy

```ruby
# app/policies/post_policy.rb
class PostPolicy
  attr_reader :user, :post

  def initialize(user, post)
    @user = user
    @post = post
  end

  def edit?
    return false unless user

    owner? || admin? || moderator?
  end

  def delete?
    return false unless user

    owner? || admin?
  end

  def publish?
    return false unless user
    return false if post.published?

    owner? || admin? || editor?
  end

  def feature?
    return false unless user

    admin? || editor?
  end

  private

  def owner?
    post.user_id == user.id
  end

  def admin?
    user.admin?
  end

  def moderator?
    user.moderator?
  end

  def editor?
    user.editor?
  end
end
```

```ruby
# app/models/post.rb (GOOD)
class Post < ApplicationRecord
  belongs_to :user

  def policy_for(user)
    PostPolicy.new(user, self)
  end
end
```

```ruby
# Usage in controllers
def edit
  @post = Post.find(params[:id])
  authorize! @post, :edit?
end

def authorize!(record, action)
  policy = record.policy_for(current_user)
  raise Unauthorized unless policy.public_send(action)
end
```

## Best Practices

### 1. Start with Tests

Always write tests before refactoring:

```ruby
# spec/services/subscriptions/create_service_spec.rb
RSpec.describe Subscriptions::CreateService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:plan) { create(:plan) }
    let(:service) { described_class.new(user: user, plan: plan) }

    context 'when successful' do
      it 'creates a subscription' do
        expect { service.call }.to change(Subscription, :count).by(1)
      end

      it 'returns success result' do
        result = service.call
        expect(result).to be_success
        expect(result.value).to be_a(Subscription)
      end

      it 'charges the user' do
        expect(PaymentProcessor).to receive(:charge).with(
          user: user,
          amount: plan.price,
          description: "Subscription to #{plan.name}"
        )

        service.call
      end
    end

    context 'when payment fails' do
      before do
        allow(PaymentProcessor).to receive(:charge).and_raise(PaymentError, 'Card declined')
      end

      it 'returns failure result' do
        result = service.call
        expect(result).to be_failure
        expect(result.error).to eq('Card declined')
      end

      it 'does not create subscription' do
        expect { service.call }.not_to change(Subscription, :count)
      end
    end
  end
end
```

### 2. Use Consistent Naming Conventions

```ruby
# Service objects
Subscriptions::CreateService
Subscriptions::CancelService
Subscriptions::UpdateService

# Query objects
Posts::TrendingQuery
Posts::PopularQuery
Users::ActiveQuery

# Form objects
RegistrationForm
ProfileUpdateForm
PaymentForm

# Policy objects
PostPolicy
UserPolicy
CommentPolicy

# Value objects
Money
DateRange
EmailAddress
PhoneNumber
```

### 3. Keep Service Objects Focused

```ruby
# Good: Single responsibility
class Orders::CreateService
  def call
    create_order
    process_payment
    send_confirmation
  end
end

# Bad: Too many responsibilities
class OrderService
  def create_order
  end

  def update_order
  end

  def cancel_order
  end

  def process_refund
  end

  def send_notifications
  end
end
```

### 4. Use Dependency Injection

```ruby
# Good: Dependencies injected
class NotificationService
  def initialize(mailer: UserMailer, logger: Rails.logger)
    @mailer = mailer
    @logger = logger
  end

  def send_notification(user, message)
    mailer.notification(user, message).deliver_later
    logger.info("Notification sent to #{user.email}")
  end

  private

  attr_reader :mailer, :logger
end

# Bad: Hard-coded dependencies
class NotificationService
  def send_notification(user, message)
    UserMailer.notification(user, message).deliver_later
    Rails.logger.info("Notification sent to #{user.email}")
  end
end
```

### 5. Return Explicit Results

```ruby
# Good: Explicit result object
class Result
  def self.success(value = nil)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end

# Usage
result = SomeService.call
if result.success?
  redirect_to result.value
else
  flash[:error] = result.error
  render :new
end

# Bad: Implicit returns
class SomeService
  def call
    # Returns different types based on outcome
    return user if user.save
    false
  end
end
```

## Common Mistakes

### 1. Over-Engineering

```ruby
# Bad: Over-engineered for simple operation
class User::Email::Normalizer::Service::V1
  def call(email)
    email.downcase.strip
  end
end

# Good: Keep it simple
class User < ApplicationRecord
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

### 2. Creating Service Objects for Everything

```ruby
# Bad: Not everything needs a service
class User::FullNameService
  def call(user)
    "#{user.first_name} #{user.last_name}".strip
  end
end

# Good: Simple methods can stay in model
class User < ApplicationRecord
  def full_name
    "#{first_name} #{last_name}".strip
  end
end
```

### 3. Not Handling Errors Properly

```ruby
# Bad: Swallowing exceptions
class SomeService
  def call
    do_something
  rescue => e
    nil
  end
end

# Good: Proper error handling
class SomeService
  def call
    do_something
    Result.success
  rescue SomeError => e
    Rails.logger.error("Service failed: #{e.message}")
    Result.failure(e.message)
  end
end
```

### 4. Mixing Responsibilities

```ruby
# Bad: Service doing too much
class UserRegistrationService
  def call
    validate_input
    create_user
    create_profile
    create_subscription
    charge_payment
    send_emails
    update_analytics
    sync_to_crm
  end
end

# Good: Compose smaller services
class UserRegistrationService
  def call
    user = Users::CreateService.call(user_params)
    Profiles::CreateService.call(user: user, profile_params: profile_params)
    Subscriptions::CreateService.call(user: user, plan: plan)
    Notifications::SendWelcomeService.call(user: user)
    Result.success(user)
  end
end
```

### 5. Not Testing Refactored Code

```ruby
# Always write tests
RSpec.describe Subscriptions::CreateService do
  # Test all paths
  context 'when successful'
  context 'when payment fails'
  context 'when user already has subscription'
  context 'when plan is invalid'
end
```

## Refactoring Checklist

- [ ] Identify code smells
- [ ] Write tests for existing behavior
- [ ] Extract service objects for complex operations
- [ ] Extract query objects for complex queries
- [ ] Extract form objects for complex forms
- [ ] Extract value objects for business concepts
- [ ] Extract decorators for view logic
- [ ] Replace callbacks with explicit service calls
- [ ] Replace conditionals with polymorphism
- [ ] Extract policy objects for authorization
- [ ] Verify all tests pass
- [ ] Remove dead code
- [ ] Update documentation
- [ ] Review with team

## Conclusion

Refactoring Rails applications is an ongoing process. Focus on:

- Identifying pain points
- Making incremental improvements
- Keeping changes small and testable
- Following SOLID principles
- Improving readability
- Reducing coupling
- Increasing cohesion

Remember: Perfect is the enemy of good. Refactor incrementally and always ensure tests pass.
