---
name: rails-packwerk
description: Shopify's Packwerk for modular Rails applications. Define packages, enforce dependencies, privacy boundaries, package.yml configuration, and migrate monolith to packages.
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - packwerk
  - modular-monolith
  - architecture
  - dependencies
  - boundaries
dependencies:
  - rails >= 6.0
  - packwerk >= 3.0
---

# Rails Packwerk

A comprehensive guide for using Packwerk to create a modular monolith in Rails. Packwerk helps enforce boundaries between components, manage dependencies, and incrementally extract your Rails application into well-defined packages.

## Use this skill when

- Breaking up a Rails monolith into packages
- Enforcing architectural boundaries in Rails apps
- Preventing unintended dependencies between modules
- Creating privacy boundaries between components
- Managing technical debt incrementally
- Preparing for potential microservices extraction
- Improving code organization in large Rails apps
- Defining domain boundaries
- Enforcing layered architecture
- Preventing circular dependencies

## Do not use this skill when

- Working with small Rails applications (< 10 models)
- The application doesn't have clear domain boundaries
- Team is not ready for stricter boundaries
- You're building microservices (use separate repos)
- The monolith works fine and doesn't need modularization

## Prerequisites

- Rails 6.0+ installed
- Understanding of domain-driven design
- Familiarity with Rails architecture
- Large or growing codebase
- Team buy-in for modularization

## Core Concepts

### What is Packwerk?

Packwerk is a Ruby gem developed by Shopify that helps enforce boundaries and modularize Rails applications by:
- Defining packages (bounded contexts)
- Enforcing privacy boundaries
- Managing dependencies between packages
- Preventing constant reference violations

### Key Concepts

1. **Packages**: Self-contained units of code with explicit dependencies
2. **Privacy**: Public vs private APIs within packages
3. **Dependencies**: Explicit declarations of package relationships
4. **Violations**: Code that breaks defined boundaries

### Package Structure

```
app/
├── packages/
│   ├── orders/
│   │   ├── app/
│   │   │   ├── models/
│   │   │   ├── services/
│   │   │   └── public/       # Public API
│   │   ├── spec/
│   │   └── package.yml
│   ├── payments/
│   │   ├── app/
│   │   ├── spec/
│   │   └── package.yml
│   └── users/
│       ├── app/
│       ├── spec/
│       └── package.yml
```

## Step-by-Step Implementation

### Step 1: Install Packwerk

```ruby
# Gemfile
gem 'packwerk'
```

```bash
bundle install
bundle exec packwerk init
```

This creates:
- `packwerk.yml` - Configuration file
- `package.yml` - Root package configuration

### Step 2: Configure Packwerk

```yaml
# packwerk.yml
inflections_file: config/inflections.yml

package_paths:
  - app/packages/*

custom_associations:
  - cache_key

load_paths:
  - app/packages/*/app/**

exclude:
  - '{bin,node_modules,script,tmp,vendor}/**/*'
  - 'app/packages/*/spec/**/*'

package_checkers:
  - 'Packwerk::ReferenceChecker'
  - 'Packwerk::DeprecatedReferences'

inflector:
  type: 'ActiveSupport'
```

### Step 3: Create Your First Package

```bash
# Create directory structure
mkdir -p app/packages/orders/app/models
mkdir -p app/packages/orders/app/services
mkdir -p app/packages/orders/app/public
mkdir -p app/packages/orders/spec
```

```yaml
# app/packages/orders/package.yml
enforce_dependencies: true
enforce_privacy: true

dependencies:
  - app/packages/users
  - app/packages/products

metadata:
  owner: Orders Team
  description: Order management and processing
```

### Step 4: Move Code into Packages

```ruby
# app/packages/orders/app/models/order.rb
module Orders
  class Order < ApplicationRecord
    belongs_to :user, class_name: 'Users::User'
    has_many :line_items, class_name: 'Orders::LineItem'

    validates :status, presence: true
    validates :total, numericality: { greater_than: 0 }
  end
end
```

```ruby
# app/packages/orders/app/models/line_item.rb
module Orders
  class LineItem < ApplicationRecord
    belongs_to :order, class_name: 'Orders::Order'
    belongs_to :product, class_name: 'Products::Product'

    validates :quantity, numericality: { greater_than: 0 }
    validates :price, numericality: { greater_than: 0 }
  end
end
```

### Step 5: Define Public API

```ruby
# app/packages/orders/app/public/orders_api.rb
module Orders
  module OrdersApi
    # Public interface for creating orders
    def self.create_order(user:, items:)
      Orders::CreateService.call(user: user, items: items)
    end

    # Public interface for finding orders
    def self.find_order(id)
      Orders::Order.find(id)
    end

    # Public interface for user's orders
    def self.user_orders(user_id)
      Orders::Order.where(user_id: user_id)
    end
  end
end
```

### Step 6: Run Packwerk Checks

```bash
# Check for violations
bundle exec packwerk check

# Validate package configuration
bundle exec packwerk validate

# Update package_todo.yml files
bundle exec packwerk update-todo
```

### Step 7: Handle Violations

#### Privacy Violations

```ruby
# app/packages/payments/app/services/charge_service.rb

# ❌ BAD: Accessing private API
module Payments
  class ChargeService
    def charge(order)
      # Direct access to Orders::Order (private)
      order.calculate_total # Private method
    end
  end
end

# ✅ GOOD: Use public API
module Payments
  class ChargeService
    def charge(order_id)
      # Use public API
      order = Orders::OrdersApi.find_order(order_id)
      total = Orders::OrdersApi.calculate_total(order_id)
      # Process payment
    end
  end
end
```

#### Dependency Violations

```yaml
# app/packages/payments/package.yml

# ❌ BAD: Using orders without declaring dependency
enforce_dependencies: true
dependencies: []
```

```yaml
# app/packages/payments/package.yml

# ✅ GOOD: Explicitly declare dependency
enforce_dependencies: true
dependencies:
  - app/packages/orders
```

### Step 8: Package TODO Management

```yaml
# app/packages/payments/package_todo.yml
# This file lists existing violations to be fixed

app/packages/orders:
  "Orders::Order":
    violations:
      - privacy
    files:
      - app/packages/payments/app/services/charge_service.rb
```

**Workflow:**
1. Run `packwerk update-todo` to record violations
2. Fix violations incrementally
3. Violations removed from todo file as fixed
4. Run `packwerk check` to prevent new violations

## Package Patterns

### 1. Domain-Based Packages

```
app/packages/
├── orders/           # Order management
├── payments/         # Payment processing
├── shipping/         # Shipping and fulfillment
├── inventory/        # Stock management
└── analytics/        # Reporting and analytics
```

### 2. Layer-Based Packages

```
app/packages/
├── domain/           # Core domain logic
├── infrastructure/   # External integrations
├── application/      # Use cases/services
└── presentation/     # Controllers/views
```

### 3. Bounded Context Packages

```
app/packages/
├── sales/            # Sales bounded context
│   ├── orders/
│   ├── quotes/
│   └── invoices/
└── customer_support/ # Support bounded context
    ├── tickets/
    └── knowledge_base/
```

## Advanced Configurations

### Public Folders

```yaml
# app/packages/orders/package.yml
enforce_privacy: true

# Files in these folders are public
public_path: app/public/

# Alternative: Use public_files pattern
public_files:
  - app/models/order.rb
  - app/services/create_service.rb
```

### Custom Associations

```yaml
# packwerk.yml
custom_associations:
  - cache_key
  - presenter
  - decorator
```

```ruby
# This allows Packwerk to track these custom associations
class Order < ApplicationRecord
  def presenter
    OrderPresenter.new(self)
  end
end
```

### Ignore Specific Files

```yaml
# package.yml
exclude:
  - app/models/legacy/**/*
  - app/services/deprecated/**/*
```

## Migration Strategies

### Strategy 1: Start with Layers

```bash
# Step 1: Create layer packages
mkdir -p app/packages/models
mkdir -p app/packages/services
mkdir -p app/packages/controllers

# Step 2: Move existing code
mv app/models/* app/packages/models/app/models/
mv app/services/* app/packages/services/app/services/

# Step 3: Run Packwerk and fix violations
bundle exec packwerk update-todo
```

### Strategy 2: Extract by Domain

```bash
# Step 1: Identify a cohesive domain
# Example: Orders domain

# Step 2: Create package structure
mkdir -p app/packages/orders/app/{models,services,controllers}

# Step 3: Move related files
mv app/models/order.rb app/packages/orders/app/models/
mv app/models/line_item.rb app/packages/orders/app/models/
mv app/services/orders/ app/packages/orders/app/services/

# Step 4: Update references
# Fix namespace and dependencies

# Step 5: Verify
bundle exec packwerk check
```

### Strategy 3: Incremental Extraction

```ruby
# 1. Start with enforce_dependencies: false
# app/packages/orders/package.yml
enforce_dependencies: false
enforce_privacy: false

# 2. Move code gradually
# 3. Fix violations as you go
# 4. Enable enforcement
enforce_dependencies: true
enforce_privacy: true
```

## Testing Packages

### Package-Level Tests

```ruby
# app/packages/orders/spec/models/order_spec.rb
require 'rails_helper'

RSpec.describe Orders::Order, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:status) }
  end

  describe 'associations' do
    it { should have_many(:line_items) }
  end
end
```

### Public API Tests

```ruby
# app/packages/orders/spec/public/orders_api_spec.rb
require 'rails_helper'

RSpec.describe Orders::OrdersApi do
  describe '.create_order' do
    let(:user) { create(:user) }
    let(:items) { [{ product_id: 1, quantity: 2 }] }

    it 'creates an order' do
      expect {
        described_class.create_order(user: user, items: items)
      }.to change(Orders::Order, :count).by(1)
    end
  end
end
```

### Integration Tests

```ruby
# spec/integration/orders_flow_spec.rb
require 'rails_helper'

RSpec.describe 'Orders flow' do
  it 'creates order and processes payment' do
    user = Users::UsersApi.create_user(email: 'test@example.com')
    order = Orders::OrdersApi.create_order(user: user, items: items)
    payment = Payments::PaymentsApi.charge(order_id: order.id)

    expect(payment).to be_successful
    expect(order.reload.status).to eq('paid')
  end
end
```

## Autoloading with Packages

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    # Add package paths to autoload paths
    config.paths.add 'app/packages', glob: '*/app/*', eager_load: true

    # Alternative: Use zeitwerk
    config.autoload_paths += Dir["#{config.root}/app/packages/*/app/*"]
  end
end
```

## CI/CD Integration

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  packwerk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Run Packwerk validation
        run: bundle exec packwerk validate
      - name: Check for violations
        run: bundle exec packwerk check
      - name: Verify no new violations
        run: |
          git diff --exit-code package_todo.yml
```

## Best Practices

### 1. Start Small

```yaml
# Begin with just a few packages
app/packages/
├── core/          # Essential domain logic
└── admin/         # Admin features
```

### 2. Define Clear Boundaries

```ruby
# Good: Clear domain boundary
module Orders
  class Order
    # Order-specific logic only
  end
end

# Bad: Mixed concerns
module Orders
  class Order
    def send_shipping_notification
      # Should be in Shipping package
    end
  end
end
```

### 3. Keep Public APIs Minimal

```ruby
# app/packages/orders/app/public/orders_api.rb

# Good: Small, focused public API
module Orders
  module OrdersApi
    def self.create_order(user:, items:)
      # Implementation
    end

    def self.cancel_order(order_id:)
      # Implementation
    end
  end
end

# Bad: Exposing everything
module Orders
  module OrdersApi
    def self.create_order(...)
    def self.update_order(...)
    def self.delete_order(...)
    def self.calculate_total(...)
    def self.validate_order(...)
    # Too many public methods
  end
end
```

### 4. Document Package Ownership

```yaml
# package.yml
metadata:
  owner: Orders Team
  slack_channel: '#team-orders'
  description: Handles order creation, updates, and fulfillment
  docs: docs/packages/orders.md
```

### 5. Use Continuous Integration

```bash
# Fail CI if new violations introduced
bundle exec packwerk check --strict
```

## Common Mistakes

### 1. Circular Dependencies

```yaml
# app/packages/orders/package.yml
dependencies:
  - app/packages/payments

# app/packages/payments/package.yml
dependencies:
  - app/packages/orders  # Circular!
```

**Solution:** Introduce shared package or refactor dependencies

### 2. Over-Modularization

```bash
# Bad: Too granular
app/packages/
├── order_model/
├── order_service/
├── order_controller/
└── order_view/

# Good: Cohesive packages
app/packages/
└── orders/
```

### 3. Ignoring Violations

```yaml
# Bad: Disabling enforcement
enforce_dependencies: false
enforce_privacy: false
```

**Solution:** Fix violations incrementally using `package_todo.yml`

### 4. Not Using Public APIs

```ruby
# Bad: Direct access to internals
Orders::Order.find(id).calculate_total

# Good: Use public API
Orders::OrdersApi.calculate_total(order_id: id)
```

## Tools and Integration

### Packwerk Visualizer

```bash
# Generate dependency graph
gem install packwerk-graphviz
bundle exec packwerk-graphviz graph
```

### Packwerk Extensions

```ruby
# Gemfile
gem 'packwerk-extensions'  # Additional checkers
gem 'packwerk-graphviz'    # Visualization
```

## Monitoring Package Health

### Metrics to Track

1. **Violation Count**: Should decrease over time
2. **Package Size**: Keep packages focused
3. **Dependency Count**: Fewer is better
4. **Public API Size**: Minimal surface area
5. **Test Coverage**: Per-package coverage

### Reporting

```bash
# Generate violation report
bundle exec packwerk check > packwerk_report.txt

# Count violations per package
grep -c "violations:" app/packages/*/package_todo.yml
```

## Conclusion

Packwerk helps create maintainable Rails monoliths by:
- Enforcing architectural boundaries
- Making dependencies explicit
- Creating clear public APIs
- Preventing unintended coupling
- Enabling incremental refactoring

**Key Principles:**
- Start small, grow incrementally
- Define clear package boundaries
- Keep public APIs minimal
- Fix violations continuously
- Document ownership

**Remember:** Packwerk is a tool for gradual improvement. It's okay to have violations initially—focus on preventing new ones and fixing existing ones incrementally.
