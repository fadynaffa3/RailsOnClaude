# Ruby Idioms & Best Practices

Patterns for idiomatic Ruby code and common anti-patterns to avoid.

## Modern Ruby 3.x Features

### Shorthand Hash Syntax
```ruby
# Bad
def create_user(name:, email:)
  User.create(name: name, email: email)
end

# Good
def create_user(name:, email:)
  User.create(name:, email:)
end
```

### Endless Methods
```ruby
# Traditional
def full_name
  "#{first_name} #{last_name}"
end

# Endless (Ruby 3.0+)
def full_name = "#{first_name} #{last_name}"
```

### Pattern Matching
```ruby
# Traditional
case response
when success_response
  handle_success(response)
when error_response
  handle_error(response)
end

# Pattern Matching (Ruby 3.0+)
case response
in { status: 200, body: }
  handle_success(body)
in { status: 404 }
  handle_not_found
in { status: code, error: message }
  handle_error(code, message)
end
```

## Enumerable Best Practices

### Use Appropriate Enumerable Methods
```ruby
# Bad - using each when map is appropriate
results = []
items.each { |item| results << item.transform }

# Good
results = items.map(&:transform)

# Bad - using map when select is appropriate
items.map { |item| item if item.active? }.compact

# Good
items.select(&:active?)

# Bad - using each when any?/all? is appropriate
found = false
items.each { |item| found = true if item.matches? }

# Good
found = items.any?(&:matches?)
```

### Prefer Symbol to_proc
```ruby
# Bad
users.map { |u| u.name }

# Good
users.map(&:name)

# Bad
numbers.select { |n| n.even? }

# Good
numbers.select(&:even?)
```

## Safe Navigation

### Use Safe Navigation Operator
```ruby
# Bad
user.address.city if user && user.address

# Good
user&.address&.city

# Bad
items.first.name if items && items.any?

# Good
items&.first&.name
```

## String Manipulation

### Avoid String Concatenation in Loops
```ruby
# Bad - creates new string objects on each iteration
result = ""
1000.times { |i| result += i.to_s }

# Good - uses mutable string
result = String.new
1000.times { |i| result << i.to_s }

# Better - use array join
result = 1000.times.map(&:to_s).join
```

### Use String Interpolation
```ruby
# Bad
"Hello, " + user.name + "!"

# Good
"Hello, #{user.name}!"
```

## Exception Handling

### Never Rescue Exception
```ruby
# Bad - catches SystemExit, SignalException, etc.
begin
  risky_operation
rescue Exception => e
  log_error(e)
end

# Good - catch StandardError (default)
begin
  risky_operation
rescue => e
  log_error(e)
end

# Better - catch specific exceptions
begin
  risky_operation
rescue ActiveRecord::RecordNotFound => e
  handle_not_found(e)
rescue ValidationError => e
  handle_validation_error(e)
end
```

### Avoid Bare Rescue
```ruby
# Bad - silently catches all StandardErrors
def process
  risky_operation
rescue
  nil
end

# Good - explicit rescue with logging
def process
  risky_operation
rescue StandardError => e
  logger.error("Failed to process: #{e.message}")
  nil
end
```

### Use Ensure for Cleanup
```ruby
# Bad
file = File.open("data.txt")
process(file)
file.close

# Good
file = File.open("data.txt")
begin
  process(file)
ensure
  file.close
end

# Better - use block form
File.open("data.txt") do |file|
  process(file)
end  # file closed automatically
```

## Method Definitions

### Use Keyword Arguments
```ruby
# Bad - positional arguments hard to understand at call site
def create_user(name, email, admin, active)
  # ...
end

create_user("John", "john@example.com", true, false)  # What do true/false mean?

# Good - keyword arguments self-document
def create_user(name:, email:, admin: false, active: true)
  # ...
end

create_user(name: "John", email: "john@example.com", admin: true)
```

### Prefer Implicit Return
```ruby
# Bad
def full_name
  return "#{first_name} #{last_name}"
end

# Good
def full_name
  "#{first_name} #{last_name}"
end

# Use explicit return only for early returns
def process
  return nil unless valid?
  perform_processing
end
```

## Boolean Methods

### Use Question Mark Suffix
```ruby
# Bad
def admin
  role == "admin"
end

# Good
def admin?
  role == "admin"
end
```

### Avoid Double Negatives
```ruby
# Bad
unless !user.inactive?
  # ...
end

# Good
if user.active?
  # ...
end
```

## Metaprogramming

### Avoid Excessive method_missing
```ruby
# Bad - unclear, hard to debug, slow
def method_missing(method, *args)
  if method.to_s.start_with?("find_by_")
    attribute = method.to_s.sub("find_by_", "")
    find_by_attribute(attribute, args.first)
  else
    super
  end
end

# Good - explicit methods or define_method
ATTRIBUTES.each do |attr|
  define_method("find_by_#{attr}") do |value|
    find_by_attribute(attr, value)
  end
end
```

### Prefer define_method for Dynamic Methods
```ruby
# Bad - eval is dangerous and hard to debug
eval <<-RUBY
  def #{name}
    @#{name}
  end
RUBY

# Good - define_method is safer
define_method(name) do
  instance_variable_get("@#{name}")
end
```

## Performance Patterns

### Use Parallel Assignment Sparingly
```ruby
# Bad - creates temporary array
a, b = b, a

# Good for simple swaps
temp = a
a = b
b = temp

# Parallel assignment is fine for multiple return values
lat, lon = geocode(address)
```

### Prefer ||= for Memoization
```ruby
# Bad - always computes
def expensive_value
  @expensive_value = compute_expensive_value
end

# Good - computes once
def expensive_value
  @expensive_value ||= compute_expensive_value
end

# Careful with falsy values
def boolean_value
  @boolean_value = compute_boolean if @boolean_value.nil?
  @boolean_value
end
```

### Use Fetch for Hash Defaults
```ruby
# Bad - returns nil if key missing
config[:timeout]

# Good - raises KeyError if key missing
config.fetch(:timeout)

# Good - provides default
config.fetch(:timeout, 30)

# Good - computed default
config.fetch(:timeout) { compute_default_timeout }
```

## Code Organization

### One Class Per File
```ruby
# Bad - multiple classes in one file
# app/models/user.rb
class User < ApplicationRecord
end

class UserPolicy
end

# Good - separate files
# app/models/user.rb
class User < ApplicationRecord
end

# app/policies/user_policy.rb
class UserPolicy
end
```

### Namespace Modules
```ruby
# Bad
class OrderProcessor
end

class OrderValidator
end

# Good
module Orders
  class Processor
  end

  class Validator
  end
end
```

## Common Anti-Patterns

### Unnecessary Variables
```ruby
# Bad
def total
  sum = items.sum(&:price)
  sum
end

# Good
def total
  items.sum(&:price)
end
```

### Verbose Conditionals
```ruby
# Bad
if user.admin? == true
  # ...
end

# Good
if user.admin?
  # ...
end

# Bad
status == "active" ? true : false

# Good
status == "active"
```

### Nested Conditionals
```ruby
# Bad
if user
  if user.admin?
    if user.active?
      grant_access
    end
  end
end

# Good
return unless user&.admin? && user.active?
grant_access

# Or use guard clauses
def process
  return unless user
  return unless user.admin?
  return unless user.active?
  
  grant_access
end
```
