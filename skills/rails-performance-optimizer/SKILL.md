---
name: rails-performance-optimizer
description: Memory profiling, response time optimization, asset optimization, caching strategies, and performance monitoring for Rails applications
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - performance
  - optimization
  - profiling
  - caching
  - memory
  - speed
dependencies:
  - rails >= 7.0
  - rack-mini-profiler (recommended)
  - bullet (recommended)
---

# Rails Performance Optimizer

A comprehensive guide for identifying and resolving performance bottlenecks in Ruby on Rails applications. This skill covers memory profiling, database optimization, caching strategies, asset optimization, and response time improvements.

## Use this skill when

- Application response times are slow
- Memory usage is high or growing
- Database queries are inefficient
- Pages load slowly
- API endpoints have high latency
- Background jobs are taking too long
- Experiencing N+1 query problems
- Need to implement caching strategies
- Asset loading is slow
- Need to optimize database indexes
- Memory leaks are suspected
- CPU usage is high
- Need to profile code execution
- Scaling issues are occurring
- Load testing reveals bottlenecks

## Do not use this skill when

- Application is already performant
- Premature optimization (measure first!)
- Infrastructure issues (not code-related)
- Network latency is the primary issue
- Third-party API latency is the bottleneck

## Prerequisites

- Rails 7.0+ application
- Access to production-like data
- Ability to run performance profiling tools
- Understanding of database queries
- Basic knowledge of caching
- Familiarity with Ruby profiling tools

## Performance Audit Checklist

### Phase 1: Install Profiling Tools

```ruby
# Gemfile
group :development do
  gem 'rack-mini-profiler'     # Performance profiling
  gem 'memory_profiler'        # Memory usage analysis
  gem 'stackprof'              # CPU profiling
  gem 'bullet'                 # N+1 query detection
  gem 'prosopite'              # N+1 query detection (alternative)
  gem 'derailed_benchmarks'    # Benchmarking tools
  gem 'benchmark-ips'          # Benchmark iterations per second
end

gem 'bootsnap', require: false # Boot time optimization
gem 'oj'                       # Fast JSON parsing
gem 'rack-timeout'             # Request timeout protection
```

```bash
bundle install
```

### Phase 2: Enable Development Tools

#### Configure Rack Mini Profiler

```ruby
# config/initializers/rack_profiler.rb
if Rails.env.development?
  require 'rack-mini-profiler'

  Rack::MiniProfiler.config.tap do |config|
    config.position = 'bottom-right'
    config.start_hidden = false

    # Skip profiling for specific paths
    config.skip_paths << '/assets'

    # Save profile data to Redis for sharing
    # config.storage = Rack::MiniProfiler::RedisStore
  end
end
```

#### Configure Bullet

```ruby
# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true

  # Slack notifications
  # Bullet.slack = { webhook_url: 'https://hooks.slack.com/...' }
end
```

### Phase 3: Database Query Optimization

#### Identify N+1 Queries

```ruby
# Bad: N+1 query
@posts = Post.all
@posts.each do |post|
  puts post.user.name       # Queries database for each post
  puts post.comments.count  # Queries database for each post
end

# Good: Eager loading
@posts = Post.includes(:user, :comments).all
@posts.each do |post|
  puts post.user.name
  puts post.comments.count
end
```

#### Use Includes vs Joins vs Preload

```ruby
# includes - Load associations (LEFT OUTER JOIN or separate queries)
Post.includes(:comments)

# joins - SQL INNER JOIN (doesn't load associations)
Post.joins(:comments).where(comments: { approved: true })

# preload - Always use separate queries
Post.preload(:comments)

# eager_load - Always use LEFT OUTER JOIN
Post.eager_load(:comments)

# Complex example with conditions
Post.includes(:user, comments: :author)
  .where(published: true)
  .where(users: { verified: true })
  .eager_load(:user) # Force JOIN for where clause
  .preload(comments: :author) # Separate queries for comments
```

#### Select Only Needed Columns

```ruby
# Bad: Loads all columns
@users = User.all

# Good: Select specific columns
@users = User.select(:id, :name, :email)

# With associations
Post.includes(:user).select('posts.*, users.name as user_name')
```

#### Use pluck and ids

```ruby
# Bad: Instantiates objects
user_ids = User.where(active: true).map(&:id)

# Good: Direct SQL
user_ids = User.where(active: true).pluck(:id)

# Even better for IDs
user_ids = User.where(active: true).ids

# Multiple columns
names_and_emails = User.pluck(:name, :email)
# Returns: [["John", "john@example.com"], ["Jane", "jane@example.com"]]
```

#### Batch Processing

```ruby
# Bad: Loads all records into memory
User.all.each do |user|
  user.send_email
end

# Good: Process in batches
User.find_each(batch_size: 1000) do |user|
  user.send_email
end

# With batch processing
User.in_batches(of: 1000) do |batch|
  batch.update_all(processed: true)
end
```

#### Counter Caches

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# app/models/user.rb
class User < ApplicationRecord
  has_many :posts
end

# Migration
class AddPostsCountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :posts_count, :integer, default: 0, null: false

    # Backfill existing counts
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          User.reset_counters(user.id, :posts)
        end
      end
    end
  end
end

# Usage - No additional query needed
@user.posts_count  # Uses counter_cache column instead of COUNT(*)
```

#### Database Indexes

```ruby
# db/migrate/xxx_add_indexes.rb
class AddIndexes < ActiveRecord::Migration[7.1]
  def change
    # Single column indexes
    add_index :posts, :user_id
    add_index :posts, :published_at
    add_index :posts, :status

    # Composite indexes (order matters!)
    add_index :posts, [:user_id, :published_at]
    add_index :posts, [:status, :created_at]

    # Unique indexes
    add_index :users, :email, unique: true

    # Partial indexes (PostgreSQL)
    add_index :posts, :user_id, where: "published_at IS NOT NULL"

    # Covering indexes (PostgreSQL)
    add_index :posts, :user_id, include: [:title, :published_at]
  end
end
```

#### Analyze Query Plans

```ruby
# In Rails console
User.where(email: 'test@example.com').explain

# Raw SQL explain
ActiveRecord::Base.connection.execute('EXPLAIN ANALYZE SELECT * FROM users WHERE email = "test@example.com"')

# app/models/concerns/explainable.rb
module Explainable
  extend ActiveSupport::Concern

  class_methods do
    def explain_query(*args)
      where(*args).explain
    end
  end
end

# Usage
User.explain_query(email: 'test@example.com')
```

### Phase 4: Caching Strategies

#### Page Caching (Static HTML)

```ruby
# config/environments/production.rb
config.action_controller.perform_caching = true
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  caches_page :index, :show

  def index
    @posts = Post.published.order(created_at: :desc).limit(10)
  end
end

# Clear cache when needed
expire_page action: :index
```

#### Action Caching (Deprecated - Use Fragment Caching)

```ruby
# Don't use action caching - it's deprecated
# Use fragment caching or HTTP caching instead
```

#### Fragment Caching

```ruby
# app/views/posts/index.html.erb
<% cache ['posts', @posts.maximum(:updated_at)] do %>
  <div class="posts">
    <% @posts.each do |post| %>
      <%= render post %>
    <% end %>
  </div>
<% end %>

# app/views/posts/_post.html.erb
<% cache post do %>
  <div class="post">
    <h2><%= post.title %></h2>
    <p><%= post.body %></p>
    <%= render 'comments/list', comments: post.comments %>
  </div>
<% end %>
```

#### Russian Doll Caching

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user, touch: true
  has_many :comments, dependent: :destroy

  def cache_key_with_version
    "posts/#{id}-#{updated_at.to_i}"
  end
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post, touch: true

  def cache_key_with_version
    "comments/#{id}-#{updated_at.to_i}"
  end
end

# app/views/posts/_post.html.erb
<% cache post do %>
  <div class="post">
    <h2><%= post.title %></h2>
    <p><%= post.body %></p>

    <div class="comments">
      <% post.comments.each do |comment| %>
        <% cache comment do %>
          <div class="comment">
            <%= comment.body %>
          </div>
        <% end %>
      <% end %>
    </div>
  </div>
<% end %>
```

#### Low-Level Caching

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def expensive_calculation
    Rails.cache.fetch(['users', id, 'expensive_calculation'], expires_in: 12.hours) do
      # Perform expensive calculation
      sleep 5
      "expensive result"
    end
  end

  def follower_count
    Rails.cache.fetch(['users', id, 'follower_count'], expires_in: 5.minutes) do
      followers.count
    end
  end
end

# Explicit cache management
Rails.cache.write('key', 'value', expires_in: 1.hour)
Rails.cache.read('key')
Rails.cache.delete('key')
Rails.cache.exist?('key')

# Increment/Decrement (Redis)
Rails.cache.increment('counter')
Rails.cache.decrement('counter')
```

#### HTTP Caching (ETag & Last-Modified)

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])

    # ETag caching
    if stale?(etag: @post, last_modified: @post.updated_at)
      respond_to do |format|
        format.html
        format.json { render json: @post }
      end
    end
  end

  def index
    @posts = Post.all

    # Collection ETag
    if stale?(etag: @posts, last_modified: @posts.maximum(:updated_at))
      respond_to do |format|
        format.html
        format.json { render json: @posts }
      end
    end
  end
end
```

#### Cache Store Configuration

```ruby
# config/environments/production.rb

# Redis (recommended for multi-server setups)
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  namespace: 'myapp',
  expires_in: 1.hour,
  connect_timeout: 1,
  read_timeout: 1,
  write_timeout: 1,
  reconnect_attempts: 2
}

# Memcached
config.cache_store = :mem_cache_store, 'cache-1.example.com', 'cache-2.example.com'

# File cache (development)
config.cache_store = :file_store, Rails.root.join('tmp', 'cache')

# Memory (development/test only)
config.cache_store = :memory_store, { size: 64.megabytes }
```

### Phase 5: Background Job Optimization

#### Move Slow Operations to Background

```ruby
# Bad: Synchronous in controller
class UsersController < ApplicationController
  def create
    @user = User.create!(user_params)
    UserMailer.welcome_email(@user).deliver_now    # Blocks request
    AnalyticsService.track_signup(@user)           # Blocks request
    CrmService.sync_user(@user)                    # Blocks request

    redirect_to @user
  end
end

# Good: Async with background jobs
class UsersController < ApplicationController
  def create
    @user = User.create!(user_params)

    # Non-blocking
    UserMailer.welcome_email(@user).deliver_later
    AnalyticsTrackingJob.perform_later('signup', @user.id)
    CrmSyncJob.perform_later(@user.id)

    redirect_to @user
  end
end
```

#### Optimize Background Jobs

```ruby
# app/jobs/bulk_import_job.rb
class BulkImportJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    # Bad: Load all records into memory
    data = CSV.read(file_path)
    data.each do |row|
      User.create!(name: row[0], email: row[1])
    end

    # Good: Stream and batch insert
    users = []
    CSV.foreach(file_path, headers: true) do |row|
      users << { name: row['name'], email: row['email'], created_at: Time.current, updated_at: Time.current }

      if users.size >= 1000
        User.insert_all!(users)
        users = []
      end
    end

    User.insert_all!(users) if users.any?
  end
end
```

### Phase 6: Memory Optimization

#### Profile Memory Usage

```ruby
# Gemfile
gem 'memory_profiler'

# Script to profile memory
require 'memory_profiler'

report = MemoryProfiler.report do
  # Code to profile
  User.includes(:posts).limit(100).each do |user|
    puts user.name
    user.posts.each { |post| puts post.title }
  end
end

report.pretty_print
```

#### Identify Memory Leaks

```ruby
# app/models/concerns/memory_leak_detector.rb
module MemoryLeakDetector
  def self.check
    GC.start
    before = ObjectSpace.count_objects

    yield

    GC.start
    after = ObjectSpace.count_objects

    diff = after.map { |k, v| [k, v - before[k]] }.to_h
    puts "Memory delta: #{diff.inspect}"
  end
end

# Usage
MemoryLeakDetector.check do
  1000.times { User.first }
end
```

#### Reduce Object Allocations

```ruby
# Bad: Creates many intermediate strings
def full_name
  "#{first_name} #{middle_name} #{last_name}".strip
end

# Good: Frozen string literals
# frozen_string_literal: true

def full_name
  [first_name, middle_name, last_name].compact.join(' ')
end

# Bad: Creating arrays unnecessarily
users.map(&:id).include?(user_id)

# Good: Use any? with block
users.any? { |u| u.id == user_id }
```

#### Use Lazy Enumerators

```ruby
# Bad: Loads all records into memory
User.all.select { |u| u.active? }.map(&:email).first(10)

# Good: Use ActiveRecord queries
User.where(active: true).limit(10).pluck(:email)

# With Ruby enumerators
(1..Float::INFINITY).lazy
  .select { |n| n.even? }
  .first(10)
```

### Phase 7: Asset Optimization

#### Configure Asset Pipeline

```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true
config.public_file_server.enabled = true
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000, immutable'
}

# Use CDN
config.asset_host = ENV['CDN_HOST']
```

#### Image Optimization

```ruby
# Gemfile
gem 'image_processing'

# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar

  def avatar_variant(size:)
    avatar.variant(
      resize_to_limit: [size, size],
      format: :webp,
      saver: { quality: 80 }
    )
  end
end

# app/views/users/_user.html.erb
<%= image_tag user.avatar_variant(size: 100), loading: :lazy %>
```

#### JavaScript Optimization

```javascript
// app/javascript/application.js

// Use dynamic imports for code splitting
document.addEventListener('DOMContentLoaded', () => {
  const dashboardElement = document.querySelector('#dashboard');

  if (dashboardElement) {
    import('./dashboard').then(module => {
      module.initDashboard();
    });
  }
});

// Debounce expensive operations
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Usage
const searchInput = document.querySelector('#search');
searchInput.addEventListener('input', debounce((e) => {
  performSearch(e.target.value);
}, 300));
```

#### CSS Optimization

```ruby
# Use CSS purging to remove unused CSS
# package.json
{
  "scripts": {
    "build:css": "postcss app/assets/stylesheets/application.css -o public/assets/application.css"
  },
  "devDependencies": {
    "@fullhuman/postcss-purgecss": "^5.0.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "postcss-cli": "^10.0.0"
  }
}

# postcss.config.js
module.exports = {
  plugins: [
    require('autoprefixer'),
    require('@fullhuman/postcss-purgecss')({
      content: [
        './app/views/**/*.html.erb',
        './app/helpers/**/*.rb',
        './app/javascript/**/*.js'
      ],
      defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || []
    })
  ]
}
```

### Phase 8: Database Connection Pooling

```ruby
# config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  reaping_frequency: 10       # Reap connections every 10 seconds
  checkout_timeout: 5         # Wait 5 seconds for a connection

# For high-concurrency apps
production:
  adapter: postgresql
  pool: 25
  checkout_timeout: 5
```

#### Connection Pool Monitoring

```ruby
# config/initializers/connection_pool_monitor.rb
ActiveSupport::Notifications.subscribe('checkout.active_record') do |name, start, finish, id, payload|
  duration = finish - start

  if duration > 1.0 # Log if checkout takes more than 1 second
    Rails.logger.warn(
      "Slow connection checkout: #{duration.round(2)}s",
      pool_size: payload[:connection].pool.size,
      connections_in_use: payload[:connection].pool.connections.count(&:in_use?)
    )
  end
end
```

### Phase 9: Query Result Caching

```ruby
# Enable query caching in controllers (enabled by default)
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_action :query_cache

  private

  def query_cache(&block)
    ActiveRecord::Base.cache(&block)
  end
end

# Manual query caching
ActiveRecord::Base.cache do
  # Queries in this block will be cached
  User.find(1)
  User.find(1) # Hits cache, doesn't query database
end

# app/models/user.rb
class User < ApplicationRecord
  def self.active_users
    uncached do
      # Force query even if caching is enabled
      where(active: true).to_a
    end
  end
end
```

### Phase 10: Monitoring and Profiling

#### Application Performance Monitoring (APM)

```ruby
# Gemfile - Choose one
gem 'newrelic_rpm'           # New Relic
gem 'skylight'               # Skylight
gem 'scout_apm'              # Scout APM
gem 'elastic-apm'            # Elastic APM

# config/initializers/scout_apm.rb
ScoutApm::Config.instance.tap do |config|
  config.key = ENV['SCOUT_KEY']
  config.name = 'My Rails App'
  config.monitor = true
end
```

#### Custom Performance Tracking

```ruby
# app/controllers/concerns/performance_tracker.rb
module PerformanceTracker
  extend ActiveSupport::Concern

  included do
    around_action :track_performance
  end

  private

  def track_performance
    start_time = Time.current
    memory_before = `ps -o rss= -p #{Process.pid}`.to_i

    yield

    duration = ((Time.current - start_time) * 1000).round(2)
    memory_after = `ps -o rss= -p #{Process.pid}`.to_i
    memory_used = memory_after - memory_before

    Rails.logger.info(
      action: "#{controller_name}##{action_name}",
      duration_ms: duration,
      memory_mb: (memory_used / 1024.0).round(2),
      view_runtime: view_runtime,
      db_runtime: db_runtime
    )
  end
end
```

#### Slow Query Logging

```ruby
# config/initializers/slow_query_logger.rb
ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
  duration = (finish - start) * 1000

  if duration > 100 # Log queries slower than 100ms
    Rails.logger.warn(
      "Slow Query (#{duration.round(2)}ms): #{payload[:sql]}",
      binds: payload[:binds],
      name: payload[:name]
    )
  end
end
```

## Best Practices

### 1. Measure First, Optimize Second

```ruby
# Always benchmark before and after
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('map.compact') { [1, nil, 2, nil, 3].map(&:to_s).compact }
  x.report('select.map') { [1, nil, 2, nil, 3].select(&:present?).map(&:to_s) }

  x.compare!
end
```

### 2. Use Database Explain Plans

```ruby
# Analyze queries before optimizing
User.joins(:posts).where(posts: { published: true }).explain

# Look for:
# - Full table scans
# - Missing indexes
# - Inefficient joins
```

### 3. Monitor Production Performance

```ruby
# Set up alerts for performance degradation
# config/initializers/performance_alerts.rb
ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)

  if event.duration > 1000 # Alert if request takes > 1 second
    SlackNotifier.notify(
      channel: '#performance-alerts',
      text: "Slow request: #{event.payload[:controller]}##{event.payload[:action]} (#{event.duration.round(2)}ms)"
    )
  end
end
```

### 4. Cache Expensive Calculations

```ruby
# Don't recalculate on every request
class Dashboard
  def stats
    Rails.cache.fetch('dashboard_stats', expires_in: 5.minutes) do
      {
        total_users: User.count,
        active_users: User.active.count,
        total_posts: Post.count,
        total_revenue: Order.sum(:total)
      }
    end
  end
end
```

### 5. Use Appropriate Data Structures

```ruby
# Bad: Array lookup is O(n)
user_ids = User.pluck(:id)
user_ids.include?(123) # Slow for large arrays

# Good: Set lookup is O(1)
user_ids = User.pluck(:id).to_set
user_ids.include?(123) # Fast
```

## Common Performance Mistakes

### 1. N+1 Queries

```ruby
# Bad
posts = Post.all
posts.each do |post|
  puts post.user.name # N+1 query
end

# Good
posts = Post.includes(:user)
posts.each do |post|
  puts post.user.name
end
```

### 2. Loading Too Much Data

```ruby
# Bad: Loads all columns for 10,000 users
User.limit(10000).each { |u| puts u.email }

# Good: Only load email column
User.limit(10000).pluck(:email).each { |email| puts email }

# Even better: Process in batches
User.select(:email).find_each(batch_size: 1000) { |u| puts u.email }
```

### 3. Rendering Partials in Loops

```ruby
# Bad: Partial rendering is expensive
<% @posts.each do |post| %>
  <%= render 'post_item', post: post %>
<% end %>

# Good: Use collection rendering
<%= render partial: 'post_item', collection: @posts, as: :post %>

# Even better: Cache the collection
<% cache ['posts', @posts.cache_key_with_version] do %>
  <%= render partial: 'post_item', collection: @posts, as: :post %>
<% end %>
```

### 4. Not Using Indexes

```ruby
# Slow query without index
User.where("LOWER(email) = ?", email.downcase)

# Add index
add_index :users, "LOWER(email)"

# Or use case-insensitive collation in PostgreSQL
enable_extension 'citext'
change_column :users, :email, :citext
```

### 5. Instantiating ActiveRecord Objects Unnecessarily

```ruby
# Bad: Creates objects
user_emails = User.where(active: true).map(&:email)

# Good: Direct SQL
user_emails = User.where(active: true).pluck(:email)

# Bad: Loads all columns
Post.where(user_id: user_id).count

# Good: Count query only
Post.where(user_id: user_id).size # Uses counter_cache if available
```

### 6. Heavy Computations in Views

```ruby
# Bad: Complex logic in view
# app/views/posts/show.html.erb
<% related_posts = Post.where(category: @post.category)
                      .where.not(id: @post.id)
                      .order(views: :desc)
                      .limit(5) %>

# Good: Move to controller or decorator
# app/controllers/posts_controller.rb
def show
  @post = Post.find(params[:id])
  @related_posts = @post.related_posts
end

# app/models/post.rb
def related_posts
  Post.where(category: category)
      .where.not(id: id)
      .order(views: :desc)
      .limit(5)
end
```

### 7. Not Using find_each

```ruby
# Bad: Loads all users into memory
User.all.each do |user|
  user.send_email
end

# Good: Batches of 1000
User.find_each(batch_size: 1000) do |user|
  user.send_email
end
```

## Advanced Optimization Techniques

### 1. Database Read Replicas

```ruby
# config/database.yml
production:
  primary:
    adapter: postgresql
    url: <%= ENV['DATABASE_URL'] %>
    pool: 25

  replica:
    adapter: postgresql
    url: <%= ENV['DATABASE_REPLICA_URL'] %>
    pool: 25
    replica: true

# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :replica }
end

# Route specific queries to replica
ActiveRecord::Base.connected_to(role: :reading) do
  User.where(active: true).to_a
end
```

### 2. Materialized Views (PostgreSQL)

```ruby
# db/migrate/xxx_create_user_stats_view.rb
class CreateUserStatsView < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW user_stats AS
      SELECT
        users.id,
        users.name,
        COUNT(DISTINCT posts.id) as posts_count,
        COUNT(DISTINCT comments.id) as comments_count,
        MAX(posts.created_at) as last_post_at
      FROM users
      LEFT JOIN posts ON posts.user_id = users.id
      LEFT JOIN comments ON comments.user_id = users.id
      GROUP BY users.id, users.name
    SQL

    add_index :user_stats, :id, unique: true
  end

  def down
    execute 'DROP MATERIALIZED VIEW user_stats'
  end
end

# Refresh materialized view
ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats')

# app/models/user_stat.rb
class UserStat < ApplicationRecord
  self.primary_key = 'id'

  def readonly?
    true
  end

  def self.refresh!
    connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats')
  end
end
```

### 3. Database Partitioning

```ruby
# PostgreSQL table partitioning for time-series data
class CreatePartitionedEvents < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE TABLE events (
        id BIGSERIAL,
        name VARCHAR(255),
        created_at TIMESTAMP NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      CREATE TABLE events_2024_01 PARTITION OF events
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

      CREATE TABLE events_2024_02 PARTITION OF events
        FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
    SQL
  end

  def down
    execute 'DROP TABLE events CASCADE'
  end
end
```

### 4. Full-Text Search Optimization

```ruby
# PostgreSQL full-text search
# db/migrate/xxx_add_search_index.rb
class AddSearchIndex < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE posts ADD COLUMN searchable tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(body, '')), 'B')
        ) STORED;

      CREATE INDEX posts_searchable_idx ON posts USING gin(searchable);
    SQL
  end

  def down
    remove_index :posts, name: 'posts_searchable_idx'
    remove_column :posts, :searchable
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  def self.search(query)
    where("searchable @@ plainto_tsquery('english', ?)", query)
      .order(Arel.sql("ts_rank(searchable, plainto_tsquery('english', '#{sanitize_sql(query)}')) DESC"))
  end
end
```

### 5. Redis for Hot Data

```ruby
# app/services/trending_posts.rb
class TrendingPosts
  REDIS_KEY = 'trending_posts'
  CACHE_DURATION = 5.minutes

  def self.top(limit = 10)
    cached = Rails.cache.read(REDIS_KEY)
    return cached if cached

    posts = Post.published
                .where('created_at > ?', 7.days.ago)
                .order(views: :desc, likes: :desc)
                .limit(limit)

    Rails.cache.write(REDIS_KEY, posts.to_a, expires_in: CACHE_DURATION)
    posts
  end

  def self.increment_view(post_id)
    # Use Redis for real-time counters
    Redis.current.zincrby('post_views', 1, post_id)
  end

  def self.sync_to_database
    # Periodically sync Redis counters to database
    post_views = Redis.current.zrange('post_views', 0, -1, with_scores: true)

    post_views.each do |post_id, views|
      Post.where(id: post_id).update_all("views = views + #{views.to_i}")
    end

    Redis.current.del('post_views')
  end
end
```

## Performance Testing Tools

### Load Testing with Apache Bench

```bash
# Simple load test
ab -n 1000 -c 10 http://localhost:3000/

# POST request with JSON
ab -n 1000 -c 10 -p data.json -T application/json http://localhost:3000/api/users
```

### Load Testing with wrk

```bash
# Install wrk
brew install wrk  # macOS

# Run test
wrk -t4 -c100 -d30s http://localhost:3000/

# With Lua script for complex scenarios
wrk -t4 -c100 -d30s -s script.lua http://localhost:3000/
```

### Profiling with stackprof

```ruby
# Gemfile
gem 'stackprof'

# Profile a code block
StackProf.run(mode: :cpu, out: 'tmp/stackprof.dump') do
  # Code to profile
  100.times { User.includes(:posts).limit(100).to_a }
end

# View results
stackprof tmp/stackprof.dump --text
```

## Conclusion

Performance optimization is an ongoing process. Key principles:

1. **Measure first** - Don't optimize without data
2. **Profile in production** - Development data isn't representative
3. **Focus on bottlenecks** - Optimize the slowest parts first
4. **Test at scale** - Use production-like data volumes
5. **Monitor continuously** - Performance can degrade over time
6. **Cache wisely** - Balance freshness vs speed
7. **Use the right tool** - Database for querying, Redis for caching, CDN for assets
8. **Keep it simple** - Complex optimizations are hard to maintain

Remember: Premature optimization is the root of all evil, but ignoring performance until it's a problem is equally bad. Strike a balance!
