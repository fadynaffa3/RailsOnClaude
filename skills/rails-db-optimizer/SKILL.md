---
name: rails-db-optimizer
description: Database optimization for Rails applications including migration best practices, index optimization, query performance analysis, and database design patterns. Helps identify missing indexes, slow queries, and provides recommendations for database performance improvements.
category: performance
---

# Rails Database Optimizer

Optimize database performance, migrations, and queries in Ruby on Rails applications.

## Use this skill when

- Optimizing slow database queries
- Adding or reviewing database indexes
- Writing database migrations
- Analyzing query performance
- Designing database schema
- Fixing N+1 query problems
- Optimizing ActiveRecord queries

## Do not use this skill when

- Writing application business logic (use rails-help)
- Testing code (use rails-test-helper)
- Reviewing general code quality (use rails-audit)

## Instructions

### Step 1: Identify Performance Issues

**Check for missing indexes:**
```ruby
# Look for foreign keys without indexes
rails db:schema:dump | grep "t.integer" | grep -v "index"

# Common patterns needing indexes:
# - Foreign keys (user_id, customer_id, etc.)
# - Polymorphic associations (commentable_type + commentable_id)
# - Columns in WHERE clauses
# - Columns in ORDER BY clauses
# - Unique constraints
```

**Analyze slow queries:**
```ruby
# In Rails console or logs
User.joins(:posts).where(posts: { published: true }).explain

# Look for:
# - Table scans (type: ALL)
# - Large row counts
# - Missing indexes (key: NULL)
```

### Step 2: Index Optimization

**Add indexes for foreign keys:**
```ruby
class AddIndexToPostsUserId < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :user_id
  end
end
```

**Composite indexes for common queries:**
```ruby
# For queries like: Post.where(user_id: X, status: 'published')
add_index :posts, [:user_id, :status]

# Order matters! Put equality conditions first, then range/order columns
add_index :posts, [:status, :created_at]  # For WHERE status = X ORDER BY created_at
```

**Polymorphic association indexes:**
```ruby
# For commentable_type + commentable_id
add_index :comments, [:commentable_type, :commentable_id]
```

**Unique indexes:**
```ruby
add_index :users, :email, unique: true
add_index :api_keys, :token, unique: true
```

**Partial indexes (PostgreSQL):**
```ruby
add_index :posts, :user_id, where: "published = true"
```

### Step 3: Query Optimization

**Use explain to analyze queries:**
```ruby
# Check query plan
Post.where(user_id: 1).explain

# Look for index usage
User.joins(:posts).where(posts: { status: 'published' }).explain
```

**Eager loading to prevent N+1:**
```ruby
# Bad: N+1 query
posts = Post.all
posts.each { |post| puts post.user.name }  # N queries!

# Good: Eager load
posts = Post.includes(:user)
posts.each { |post| puts post.user.name }  # 2 queries

# For multiple associations
posts = Post.includes(:user, :comments, tags: :category)

# Use joins for filtering (not loading associations)
Post.joins(:user).where(users: { active: true })
```

**Select only needed columns:**
```ruby
# Bad: Loads all columns
User.all

# Good: Only specific columns
User.select(:id, :name, :email)

# With pluck for simple arrays
User.pluck(:email)  # Returns array of emails
User.pluck(:id, :name)  # Returns array of [id, name] tuples
```

**Use find_each for large datasets:**
```ruby
# Bad: Loads all records into memory
User.all.each { |user| user.process }

# Good: Batch processing
User.find_each(batch_size: 100) do |user|
  user.process
end
```

**Counter caches:**
```ruby
# Migration
add_column :users, :posts_count, :integer, default: 0

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Now user.posts.count doesn't hit DB
```

### Step 4: Migration Best Practices

**Always reversible:**
```ruby
# Good: Reversible
class AddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status, :string, default: 'active'
  end
end

# Use up/down for complex changes
class ChangeUserEmailToNotNull < ActiveRecord::Migration[8.0]
  def up
    User.where(email: nil).update_all(email: 'unknown@example.com')
    change_column_null :users, :email, false
  end

  def down
    change_column_null :users, :email, true
  end
end
```

**Add indexes in separate migrations for large tables:**
```ruby
# Avoid locking tables during deployment
class AddIndexConcurrently < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!  # Required for concurrent index creation

  def change
    add_index :users, :email, algorithm: :concurrently
  end
end
```

**Never reference models in migrations:**
```ruby
# Bad: Model might change or be deleted
class MigrateUserData < ActiveRecord::Migration[8.0]
  def up
    User.find_each { |user| user.update(status: 'active') }
  end
end

# Good: Use execute or inline class
class MigrateUserData < ActiveRecord::Migration[8.0]
  class User < ApplicationRecord; end  # Inline model

  def up
    User.where(old_status: 'ok').update_all(status: 'active')
  end
end
```

**Set default values in migrations:**
```ruby
# Good: Database-level default
add_column :users, :role, :string, default: 'user', null: false

# Bad: Application-level default only (can cause issues)
add_column :users, :role, :string
# Then in model: after_initialize { self.role ||= 'user' }
```

### Step 5: Database Design Patterns

**Normalization:**
```ruby
# Separate concerns into different tables
# Example: Extract address from users table
create_table :addresses do |t|
  t.references :user, null: false, foreign_key: true
  t.string :street
  t.string :city
  t.string :country
  t.timestamps
end
```

**Denormalization (when justified):**
```ruby
# Add cached columns for frequent reads
add_column :posts, :comments_count, :integer, default: 0
add_column :posts, :cached_tags, :jsonb, default: []

# Use with counter_cache or update manually
```

**JSONB for flexible data (PostgreSQL):**
```ruby
# Migration
add_column :users, :preferences, :jsonb, default: {}
add_index :users, :preferences, using: :gin

# Usage
User.where("preferences->>'theme' = ?", 'dark')
```

### Step 6: Common Issues and Solutions

**Issue: Slow queries with LIKE**
```ruby
# Bad: Full table scan
User.where("email LIKE ?", "%@example.com")

# Better: Use database-specific features
# PostgreSQL: Full-text search
add_index :users, :email, using: :gin, opclass: :gin_trgm_ops
User.where("email % ?", "example.com")
```

**Issue: Large offset pagination**
```ruby
# Bad: Gets slower as offset increases
User.offset(10000).limit(20)

# Good: Keyset pagination
User.where("id > ?", last_id).limit(20)
```

**Issue: COUNT(*) on large tables**
```ruby
# Bad: Slow on large tables
User.count

# Good: Use counter cache or approximate
# PostgreSQL:
ActiveRecord::Base.connection.execute(
  "SELECT reltuples::bigint FROM pg_class WHERE relname = 'users'"
)
```

## Verification

After optimization:

1. **Check query plans:**
   ```ruby
   YourModel.your_query.explain
   # Verify indexes are being used
   ```

2. **Measure performance:**
   ```ruby
   require 'benchmark'

   Benchmark.ms do
     Post.includes(:user).limit(100).to_a
   end
   ```

3. **Monitor database:**
   - Check slow query logs
   - Monitor query execution time
   - Track database connection pool usage

4. **Run tests:**
   ```bash
   bundle exec rspec
   ```

## Best Practices

- **Index Strategy:**
  - Index all foreign keys
  - Index columns used in WHERE, JOIN, ORDER BY
  - Use composite indexes for multi-column queries
  - Don't over-index (slows writes)

- **Query Strategy:**
  - Use eager loading for associations
  - Batch process large datasets
  - Select only needed columns
  - Cache expensive queries

- **Migration Strategy:**
  - Always reversible
  - Test with production-like data
  - Use concurrent indexes for large tables
  - Never reference models directly

- **Monitoring:**
  - Track slow queries
  - Monitor index usage
  - Watch database size growth
  - Alert on connection pool exhaustion

## Common Mistakes to Avoid

- ❌ Adding indexes without measuring impact
- ❌ Not using eager loading (N+1 queries)
- ❌ Referencing models in migrations
- ❌ Missing indexes on foreign keys
- ❌ Using offset pagination on large datasets
- ❌ Not setting default values in database
- ❌ Over-normalizing or under-normalizing
- ❌ Ignoring database-specific optimizations
