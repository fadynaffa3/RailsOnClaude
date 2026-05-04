---
name: rails-test-helper
description: RSpec and testing best practices for Rails applications. Helps write effective tests, set up FactoryBot, configure test doubles, improve test coverage, and follow TDD/BDD patterns. Includes request specs, model specs, and integration testing guidance.
category: testing
---

# Rails Test Helper

Expert guidance for writing effective RSpec tests in Ruby on Rails applications.

## Use this skill when

- Writing new RSpec tests
- Improving test coverage
- Setting up FactoryBot factories
- Configuring test doubles and stubs
- Following TDD/BDD practices
- Debugging failing tests
- Refactoring test code

## Do not use this skill when

- Writing application code (use rails-help)
- Optimizing database queries (use rails-db-optimizer)
- Reviewing code quality (use rails-audit)

## Instructions

### Step 1: RSpec Setup

**Install RSpec:**
```bash
# Add to Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'simplecov', require: false
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
end

bundle install
rails generate rspec:install
```

**Configure spec/rails_helper.rb:**
```ruby
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
end

RSpec.configure do |config|
  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Database Cleaner
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

### Step 2: FactoryBot Patterns

**Define factories:**
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { 'password123' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end

# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    association :user

    trait :published do
      status { 'published' }
      published_at { Time.current }
    end

    trait :draft do
      status { 'draft' }
      published_at { nil }
    end
  end
end
```

**Use factories in tests:**
```ruby
# Create persisted record
user = create(:user)

# Build non-persisted record
user = build(:user)

# Build with attributes
user = build(:user, email: 'specific@example.com')

# Use traits
admin = create(:user, :admin)
user_with_posts = create(:user, :with_posts)

# Create multiple records
users = create_list(:user, 5)

# Build stubbed (no DB, faster)
user = build_stubbed(:user)
```

### Step 3: Model Specs

**Test validations:**
```ruby
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(100) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid').for(:email) }
  end

  describe 'associations' do
    it { should have_many(:posts).dependent(:destroy) }
    it { should belong_to(:company).optional }
  end

  describe 'scopes' do
    it 'returns active users' do
      active_user = create(:user, status: 'active')
      inactive_user = create(:user, status: 'inactive')

      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end
end
```

**Test methods:**
```ruby
RSpec.describe User, type: :model do
  describe '#full_name' do
    it 'returns first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end

    context 'when last name is missing' do
      it 'returns only first name' do
        user = build(:user, first_name: 'John', last_name: nil)
        expect(user.full_name).to eq('John')
      end
    end
  end

  describe '#active?' do
    it 'returns true for active users' do
      user = build(:user, status: 'active')
      expect(user).to be_active
    end

    it 'returns false for inactive users' do
      user = build(:user, status: 'inactive')
      expect(user).not_to be_active
    end
  end
end
```

### Step 4: Request Specs (Controller Tests)

**Test API endpoints:**
```ruby
RSpec.describe 'Users API', type: :request do
  describe 'GET /users' do
    it 'returns list of users' do
      create_list(:user, 3)

      get '/api/v1/users'

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end

    it 'filters by status' do
      create(:user, :active)
      create(:user, :inactive)

      get '/api/v1/users', params: { status: 'active' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe 'POST /users' do
    let(:valid_params) do
      { user: { name: 'John Doe', email: 'john@example.com' } }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/users', params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['name']).to eq('John Doe')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        { user: { name: '', email: 'invalid' } }
      end

      it 'returns error response' do
        post '/api/v1/users', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('errors')
      end
    end
  end
end
```

**Test authentication:**
```ruby
RSpec.describe 'Protected API', type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.auth_token}" } }

  describe 'GET /protected_resource' do
    context 'when authenticated' do
      it 'returns protected data' do
        get '/api/v1/protected_resource', headers: auth_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/protected_resource'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

### Step 5: Service/PORO Specs

**Test service objects:**
```ruby
RSpec.describe Users::Create do
  describe '.call' do
    let(:params) { { name: 'John', email: 'john@example.com' } }

    context 'with valid params' do
      it 'creates a user' do
        expect {
          described_class.call(params: params)
        }.to change(User, :count).by(1)
      end

      it 'sends welcome email' do
        expect(UserMailer).to receive(:welcome).and_call_original
        described_class.call(params: params)
      end

      it 'returns success result' do
        result = described_class.call(params: params)
        expect(result).to be_success
        expect(result.user).to be_a(User)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { name: '', email: 'invalid' } }

      it 'does not create a user' do
        expect {
          described_class.call(params: invalid_params)
        }.not_to change(User, :count)
      end

      it 'returns failure result' do
        result = described_class.call(params: invalid_params)
        expect(result).to be_failure
        expect(result.errors).to be_present
      end
    end
  end
end
```

### Step 6: Background Job Specs

**Test Solid Queue jobs:**
```ruby
RSpec.describe ProcessOrderJob, type: :job do
  describe '#perform' do
    let(:order) { create(:order) }

    it 'processes the order' do
      expect_any_instance_of(Orders::Processor).to receive(:process).with(order)
      described_class.perform_now(order.id)
    end

    it 'enqueues the job' do
      expect {
        described_class.perform_later(order.id)
      }.to have_enqueued_job(described_class).with(order.id)
    end

    it 'retries on failure' do
      allow_any_instance_of(Orders::Processor).to receive(:process).and_raise(StandardError)

      expect {
        described_class.perform_now(order.id)
      }.to raise_error(StandardError)
    end
  end
end
```

### Step 7: Test Doubles and Stubs

**Stub methods:**
```ruby
# Stub instance method
allow_any_instance_of(User).to receive(:active?).and_return(true)

# Stub class method
allow(User).to receive(:find).and_return(user)

# Stub with arguments
allow(UserService).to receive(:call).with(user: user).and_return(result)

# Stub configuration
allow(Rails.application.config).to receive(:api_key).and_return('test-key')
```

**Mock expectations:**
```ruby
# Expect method to be called
expect(UserMailer).to receive(:welcome).with(user).and_call_original

# Expect not to be called
expect(UserMailer).not_to receive(:welcome)

# Expect specific number of times
expect(Api::Client).to receive(:post).twice
```

**Stub external APIs:**
```ruby
# WebMock
stub_request(:get, 'https://api.example.com/users/1')
  .to_return(status: 200, body: { name: 'John' }.to_json)

# VCR
VCR.use_cassette('user_api_call') do
  User.fetch_from_api(1)
end
```

### Step 8: Shared Examples

**Define shared examples:**
```ruby
# spec/support/shared_examples/archivable.rb
RSpec.shared_examples 'archivable' do
  it 'archives the record' do
    expect(subject).to respond_to(:archive!)
    expect(subject).to respond_to(:archived?)
  end

  describe '#archive!' do
    it 'sets archived_at timestamp' do
      subject.archive!
      expect(subject.archived_at).to be_present
    end
  end
end

# Use in specs
RSpec.describe Post, type: :model do
  it_behaves_like 'archivable'
end
```

**Shared contexts:**
```ruby
# spec/support/shared_contexts/authenticated_api.rb
RSpec.shared_context 'authenticated api' do
  let(:user) { create(:user) }
  let(:token) { user.generate_token }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
end

# Use in specs
RSpec.describe 'Protected API', type: :request do
  include_context 'authenticated api'

  it 'accesses protected resource' do
    get '/api/protected', headers: headers
    expect(response).to be_successful
  end
end
```

### Step 9: Test Organization

**Use let and let!:**
```ruby
RSpec.describe UserService do
  # Lazy evaluation (only created when used)
  let(:user) { create(:user) }

  # Eager evaluation (created before each test)
  let!(:admin) { create(:user, :admin) }

  # Use subject for main object under test
  subject { described_class.new(user) }

  it 'processes user' do
    expect(subject.process).to be_truthy
  end
end
```

**Context blocks for clear scenarios:**
```ruby
RSpec.describe User do
  describe '#eligible_for_discount?' do
    context 'when user is premium' do
      let(:user) { create(:user, :premium) }

      it 'returns true' do
        expect(user.eligible_for_discount?).to be true
      end
    end

    context 'when user is regular' do
      let(:user) { create(:user, :regular) }

      context 'and has made 10+ orders' do
        before { create_list(:order, 10, user: user) }

        it 'returns true' do
          expect(user.eligible_for_discount?).to be true
        end
      end

      context 'and has made fewer than 10 orders' do
        it 'returns false' do
          expect(user.eligible_for_discount?).to be false
        end
      end
    end
  end
end
```

## Best Practices

**Four Phase Test:**
```ruby
it 'creates a post' do
  # 1. Setup
  user = create(:user)
  params = { title: 'Test', body: 'Content' }

  # 2. Exercise
  post = Posts::Create.call(user: user, params: params)

  # 3. Verify
  expect(post).to be_persisted
  expect(post.title).to eq('Test')

  # 4. Teardown (automatic with DatabaseCleaner)
end
```

**Test one thing per example:**
```ruby
# Bad: Testing multiple things
it 'creates and emails user' do
  user = create(:user)
  expect(user).to be_persisted
  expect(user.email).to be_present
  expect(UserMailer).to have_received(:welcome)
end

# Good: Separate tests
it 'creates user' do
  user = create(:user)
  expect(user).to be_persisted
end

it 'sends welcome email' do
  expect(UserMailer).to receive(:welcome)
  create(:user)
end
```

**Descriptive test names:**
```ruby
# Bad
it 'works' do
end

# Good
it 'creates a user with valid attributes' do
end

it 'returns validation errors for invalid email' do
end
```

## Common Mistakes to Avoid

- ❌ Using instance variables instead of `let`
- ❌ Mutating ENV variables in tests
- ❌ Testing implementation details instead of behavior
- ❌ Not cleaning up test data properly
- ❌ Overly mocking/stubbing (test integration when possible)
- ❌ Writing tests that depend on execution order
- ❌ Not using transactions for speed
- ❌ Ignoring flaky tests
