---
name: rails-security-audit
description: Security scanning, OWASP Top 10 vulnerabilities, authentication, authorization, and secure coding practices for Rails applications
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - security
  - owasp
  - authentication
  - authorization
  - vulnerability
  - penetration-testing
dependencies:
  - rails >= 7.0
  - brakeman (recommended)
  - bundler-audit (recommended)
---

# Rails Security Audit

A comprehensive security audit skill for Ruby on Rails applications. This skill helps identify security vulnerabilities, implement secure coding practices, and ensure compliance with OWASP Top 10 and industry security standards.

## Use this skill when

- Conducting security audits of Rails applications
- Identifying OWASP Top 10 vulnerabilities
- Reviewing authentication and authorization implementations
- Checking for SQL injection, XSS, and CSRF vulnerabilities
- Auditing secure session management
- Reviewing API security
- Checking for mass assignment vulnerabilities
- Auditing file upload security
- Reviewing password storage and encryption
- Checking for sensitive data exposure
- Auditing third-party dependencies for vulnerabilities
- Implementing security headers
- Setting up Content Security Policy (CSP)
- Reviewing logging and monitoring practices
- Preparing for security compliance (GDPR, SOC 2, PCI-DSS)

## Do not use this skill when

- Performing infrastructure security audits (use DevOps security tools)
- Testing network security (use penetration testing tools)
- The application is not built with Rails
- You need automated penetration testing (use specialized tools)
- Performing compliance audits requiring legal expertise

## Prerequisites

- Rails 7.0+ application
- Access to application source code
- Brakeman gem installed (optional but recommended)
- bundler-audit gem installed (optional but recommended)
- Understanding of OWASP Top 10
- Knowledge of Rails security features

## Security Audit Checklist

### Phase 1: Dependency Vulnerabilities

#### Install Security Tools

```ruby
# Gemfile
group :development do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'ruby_audit', require: false
end
```

```bash
bundle install
```

#### Run Bundler Audit

```bash
# Update vulnerability database
bundle audit update

# Check for vulnerable versions
bundle audit check

# Example output:
# Name: rack
# Version: 2.0.8
# CVE: CVE-2020-8184
# Criticality: High
# URL: https://nvd.nist.gov/vuln/detail/CVE-2020-8184
# Solution: upgrade to ~> 2.1.4
```

#### Automated Dependency Checks

```bash
# Add to CI/CD pipeline
bundle exec bundle-audit check --update
```

```yaml
# .github/workflows/security.yml
name: Security Audit

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      - name: Run bundler-audit
        run: |
          gem install bundler-audit
          bundle-audit update
          bundle-audit check
```

### Phase 2: Static Analysis with Brakeman

#### Run Brakeman Scan

```bash
# Basic scan
brakeman

# High confidence warnings only
brakeman -w3

# Output to file
brakeman -o report.html

# Ignore specific warnings
brakeman -i config/brakeman.ignore
```

#### Configure Brakeman

```yaml
# config/brakeman.yml
---
:skip_files:
  - "lib/templates/**/*"
  - "vendor/**/*"

:ignore_model_output: false
:check_arguments: true
:safe_methods:
  - :sanitize
  - :h
  - :html_safe

:confidence_levels:
  - high
  - medium
```

#### Common Brakeman Warnings

**SQL Injection:**
```ruby
# Bad: Vulnerable to SQL injection
User.where("name = '#{params[:name]}'")

# Good: Use parameterized queries
User.where("name = ?", params[:name])
User.where(name: params[:name])
```

**Cross-Site Scripting (XSS):**
```ruby
# Bad: User input rendered without escaping
<%= raw @user.bio %>
<%= @user.bio.html_safe %>

# Good: Escape by default
<%= @user.bio %>
<%= sanitize @user.bio %>
```

**Mass Assignment:**
```ruby
# Bad: All params passed directly
User.create(params[:user])

# Good: Use strong parameters
User.create(user_params)

private

def user_params
  params.require(:user).permit(:email, :username)
end
```

### Phase 3: OWASP Top 10 Audit

#### 1. Injection Vulnerabilities

**SQL Injection Prevention:**

```ruby
# app/models/concerns/safely_searchable.rb
module SafelySearchable
  extend ActiveSupport::Concern

  class_methods do
    def safe_search(query, columns)
      return none if query.blank?

      conditions = columns.map { |col| "#{col} ILIKE ?" }
      where(conditions.join(' OR '), *(["%#{sanitize_sql_like(query)}%"] * columns.size))
    end
  end
end

# Usage
class User < ApplicationRecord
  include SafelySearchable

  def self.search(query)
    safe_search(query, [:username, :email, :bio])
  end
end
```

**Command Injection Prevention:**

```ruby
# Bad: User input in system command
system("convert #{params[:file]} output.pdf")

# Good: Use safe methods with array syntax
system("convert", params[:file], "output.pdf")

# Better: Validate and whitelist
def safe_convert(filename)
  raise ArgumentError unless filename =~ /\A[\w\-. ]+\z/
  raise ArgumentError unless File.exist?(filename)

  system("convert", filename, "output.pdf")
end
```

**LDAP Injection Prevention:**

```ruby
# Bad: Concatenating user input
filter = "(uid=#{params[:username]})"

# Good: Use proper escaping
filter = Net::LDAP::Filter.eq('uid', params[:username])
```

#### 2. Broken Authentication

**Secure Password Storage:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :password,
    length: { minimum: 12 },
    format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
      message: 'must include uppercase, lowercase, number, and special character'
    },
    if: :password_digest_changed?

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Password age enforcement
  def password_expired?
    password_changed_at < 90.days.ago
  end

  # Prevent password reuse
  before_update :prevent_password_reuse, if: :password_digest_changed?

  private

  def prevent_password_reuse
    return unless password_hashes.include?(password_digest)

    errors.add(:password, "has been used recently. Please choose a different password.")
    throw(:abort)
  end
end
```

**Session Management:**

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_myapp_session',
  secure: Rails.env.production?,        # HTTPS only in production
  httponly: true,                        # Not accessible via JavaScript
  same_site: :lax,                       # CSRF protection
  expire_after: 30.minutes               # Auto-logout

# config/application.rb
config.force_ssl = true                  # Enforce HTTPS in production
```

**Multi-Factor Authentication:**

```ruby
# Gemfile
gem 'rotp'        # Time-based OTP
gem 'rqrcode'     # QR code generation

# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  def enable_two_factor!
    self.otp_secret = ROTP::Base32.random
    save!
  end

  def verify_otp(code)
    return false unless otp_enabled?

    totp = ROTP::TOTP.new(otp_secret)
    totp.verify(code, drift_behind: 30)
  end

  def otp_provisioning_uri(issuer)
    return unless otp_secret

    ROTP::TOTP.new(otp_secret).provisioning_uri(email, issuer_name: issuer)
  end
end

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      if user.otp_enabled?
        session[:pending_user_id] = user.id
        redirect_to two_factor_path
      else
        sign_in(user)
        redirect_to root_path
      end
    else
      render :new, alert: 'Invalid credentials'
    end
  end
end

# app/controllers/two_factor_controller.rb
class TwoFactorController < ApplicationController
  def show
    redirect_to login_path unless session[:pending_user_id]
  end

  def create
    user = User.find_by(id: session[:pending_user_id])

    if user&.verify_otp(params[:code])
      session.delete(:pending_user_id)
      sign_in(user)
      redirect_to root_path
    else
      flash.now[:alert] = 'Invalid authentication code'
      render :show
    end
  end
end
```

**Account Lockout:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 30.minutes

  def increment_failed_attempts!
    increment!(:failed_login_attempts)
    lock_account! if failed_login_attempts >= MAX_FAILED_ATTEMPTS
  end

  def reset_failed_attempts!
    update(failed_login_attempts: 0, locked_at: nil)
  end

  def account_locked?
    return false unless locked_at

    if locked_at < LOCKOUT_DURATION.ago
      reset_failed_attempts!
      false
    else
      true
    end
  end

  private

  def lock_account!
    update(locked_at: Time.current)
    UserMailer.account_locked(self).deliver_later
  end
end
```

#### 3. Sensitive Data Exposure

**Encrypted Attributes:**

```ruby
# config/credentials.yml.enc
encryption:
  primary_key: <%= Rails.application.credentials.secret_key_base %>
  deterministic_key: <%= Digest::SHA256.hexdigest(Rails.application.credentials.secret_key_base) %>

# app/models/user.rb
class User < ApplicationRecord
  encrypts :social_security_number, :credit_card_number
  encrypts :email, deterministic: true  # Allows querying

  # Blind indexes for searchable encrypted data
  blind_index :email, key: Rails.application.credentials.dig(:blind_index_key)
end

# Migration
class AddEncryptedFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :social_security_number, :text
    add_column :users, :credit_card_number, :text
  end
end
```

**Secure File Storage:**

```ruby
# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: us-east-1
  bucket: secure-uploads
  server_side_encryption: AES256  # Enable encryption at rest

# app/models/document.rb
class Document < ApplicationRecord
  has_one_attached :file

  validates :file, presence: true,
    content_type: ['application/pdf', 'image/png', 'image/jpeg'],
    size: { less_than: 10.megabytes }

  # Generate signed URLs with expiration
  def secure_url(expires_in: 1.hour)
    file.url(expires_in: expires_in)
  end

  # Virus scanning before storage
  before_save :scan_for_viruses

  private

  def scan_for_viruses
    # Integrate with ClamAV or similar
    unless VirusScanner.safe?(file)
      errors.add(:file, 'contains malicious content')
      throw(:abort)
    end
  end
end
```

**PII Handling:**

```ruby
# app/models/concerns/pii_loggable.rb
module PiiLoggable
  extend ActiveSupport::Concern

  PII_ATTRIBUTES = %i[
    email
    phone_number
    social_security_number
    credit_card_number
    date_of_birth
  ].freeze

  included do
    # Prevent PII from appearing in logs
    def inspect
      attrs = attributes.except(*PII_ATTRIBUTES.map(&:to_s))
      "#<#{self.class.name} #{attrs.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')}>"
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  include PiiLoggable

  # Filter PII from logs
  Rails.application.config.filter_parameters += PiiLoggable::PII_ATTRIBUTES
end
```

#### 4. XML External Entities (XXE)

**Secure XML Parsing:**

```ruby
# Bad: Default XML parsing is vulnerable
require 'nokogiri'
doc = Nokogiri::XML(xml_string)

# Good: Disable external entities
require 'nokogiri'
doc = Nokogiri::XML(xml_string) do |config|
  config.noent.nonet.noblanks
end

# app/services/xml_parser.rb
class XmlParser
  def self.parse(xml_string)
    Nokogiri::XML(xml_string) do |config|
      config.strict.nonet  # Disable network access
    end
  rescue Nokogiri::XML::SyntaxError => e
    Rails.logger.error("XML parsing error: #{e.message}")
    nil
  end
end
```

**API XML Input:**

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    # Only accept JSON, not XML
    before_action :ensure_json_request

    private

    def ensure_json_request
      unless request.format.json?
        render json: { error: 'Only JSON requests are accepted' }, status: :not_acceptable
      end
    end
  end
end
```

#### 5. Broken Access Control

**Authorization with Pundit:**

```ruby
# Gemfile
gem 'pundit'

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_to(request.referrer || root_path)
  end
end

# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  def index?
    true  # Anyone can view list
  end

  def show?
    record.published? || owner_or_admin?
  end

  def create?
    user.present?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  private

  def owner_or_admin?
    user.admin? || record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user
        scope.where(published: true).or(scope.where(user_id: user.id))
      else
        scope.where(published: true)
      end
    end
  end
end

# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = policy_scope(Post)
  end

  def show
    authorize @post
  end

  def create
    @post = current_user.posts.build(post_params)
    authorize @post

    if @post.save
      redirect_to @post
    else
      render :new
    end
  end

  def update
    authorize @post

    if @post.update(post_params)
      redirect_to @post
    else
      render :edit
    end
  end

  def destroy
    authorize @post
    @post.destroy
    redirect_to posts_path
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :published)
  end
end
```

**Direct Object Reference Prevention:**

```ruby
# Bad: Exposes database IDs
GET /users/1/documents/5

# Good: Use UUIDs or scoped queries
class Document < ApplicationRecord
  belongs_to :user

  before_create :generate_uuid

  def to_param
    uuid
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end

# Controller always scopes to current user
class DocumentsController < ApplicationController
  def show
    @document = current_user.documents.find_by!(uuid: params[:id])
  end
end
```

**Horizontal Privilege Escalation Prevention:**

```ruby
# Bad: No ownership check
def update
  @post = Post.find(params[:id])
  @post.update(post_params)
end

# Good: Always verify ownership
def update
  @post = current_user.posts.find(params[:id])
  @post.update(post_params)
end

# Even better: Use authorization gem
def update
  @post = Post.find(params[:id])
  authorize @post
  @post.update(post_params)
end
```

#### 6. Security Misconfiguration

**Security Headers:**

```ruby
# config/application.rb
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'DENY',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block',
  'X-Download-Options' => 'noopen',
  'X-Permitted-Cross-Domain-Policies' => 'none',
  'Referrer-Policy' => 'strict-origin-when-cross-origin'
}

# Gemfile
gem 'secure_headers'

# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]

  config.csp = {
    default_src: %w['self'],
    font_src: %w['self' data: https://fonts.gstatic.com],
    img_src: %w['self' data: https:],
    object_src: %w['none'],
    script_src: %w['self' https://cdn.jsdelivr.net],
    style_src: %w['self' 'unsafe-inline' https://fonts.googleapis.com],
    base_uri: %w['self'],
    form_action: %w['self'],
    frame_ancestors: %w['none'],
    upgrade_insecure_requests: true
  }
end
```

**Environment Configuration:**

```ruby
# config/environments/production.rb
Rails.application.configure do
  # Force SSL
  config.force_ssl = true
  config.ssl_options = {
    redirect: { exclude: ->(request) { request.path =~ /health/ } }
  }

  # Secure cookies
  config.session_store :cookie_store,
    key: '_myapp_session',
    secure: true,
    httponly: true,
    same_site: :strict

  # Disable detailed error pages
  config.consider_all_requests_local = false

  # Don't fallback to assets pipeline
  config.assets.compile = false

  # Logging
  config.log_level = :info
  config.log_tags = [:request_id]

  # Don't log sensitive data
  config.filter_parameters += [
    :password,
    :password_confirmation,
    :credit_card,
    :ssn,
    :api_key,
    :token
  ]
end
```

**Disable Unused Features:**

```ruby
# config/application.rb
config.api_only = true  # If building API-only app

# Disable XML parsing if not needed
config.middleware.delete ActionDispatch::XmlParamsParser

# config/routes.rb
Rails.application.routes.draw do
  # Disable format-based routing if not needed
  defaults format: :json do
    namespace :api do
      # routes
    end
  end
end
```

#### 7. Cross-Site Scripting (XSS)

**Output Encoding:**

```ruby
# app/views/users/show.html.erb

# Good: Automatic escaping (default)
<h1><%= @user.username %></h1>
<p><%= @user.bio %></p>

# Bad: Don't do this unless absolutely necessary
<%= raw @user.bio %>
<%= @user.bio.html_safe %>

# Better: Sanitize user content
<%= sanitize @user.bio, tags: %w[p br strong em], attributes: [] %>
```

**Content Security Policy:**

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, 'https://fonts.gstatic.com'
    policy.img_src     :self, :data, 'https:'
    policy.object_src  :none
    policy.script_src  :self, 'https://cdn.jsdelivr.net'
    policy.style_src   :self, 'https://fonts.googleapis.com'

    # Disable inline scripts/styles
    policy.script_src :self
    policy.style_src  :self

    # Report violations
    if Rails.env.production?
      policy.report_uri '/csp-violation-report-endpoint'
    end
  end

  # Generate nonce for inline scripts if needed
  content_security_policy_nonce_generator do |request|
    SecureRandom.base64(16)
  end

  content_security_policy_nonce_directives %w[script-src]
end
```

**JSON Responses:**

```ruby
# app/controllers/api/base_controller.rb
before_action :set_content_type

private

def set_content_type
  response.headers['Content-Type'] = 'application/json; charset=utf-8'
  response.headers['X-Content-Type-Options'] = 'nosniff'
end
```

#### 8. Insecure Deserialization

**Avoid Marshal/YAML for Untrusted Data:**

```ruby
# Bad: Deserializing user input
data = Marshal.load(params[:data])  # NEVER do this
data = YAML.load(params[:data])     # NEVER do this

# Good: Use JSON
data = JSON.parse(params[:data])

# Better: Use safe YAML loading
data = YAML.safe_load(params[:data], permitted_classes: [Symbol, Date, Time])
```

**Session Security:**

```ruby
# config/initializers/session_store.rb
# Use encrypted cookie store (default in Rails 5.2+)
Rails.application.config.session_store :cookie_store,
  key: '_myapp_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax

# For sensitive applications, use database or Redis sessions
# config/initializers/session_store.rb
Rails.application.config.session_store :active_record_store,
  key: '_myapp_session',
  secure: Rails.env.production?,
  httponly: true,
  expire_after: 30.minutes
```

#### 9. Using Components with Known Vulnerabilities

**Automated Dependency Scanning:**

```bash
# Check for vulnerabilities
bundle audit check

# Update gems regularly
bundle update

# Check for outdated gems
bundle outdated
```

**Dependabot Configuration:**

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
```

**Gem Version Pinning:**

```ruby
# Gemfile
# Good: Pin major/minor versions
gem 'rails', '~> 7.1.0'
gem 'devise', '~> 4.9'

# Be cautious with loose constraints
gem 'some_gem', '>= 1.0'  # Could pull in breaking changes
```

#### 10. Insufficient Logging & Monitoring

**Security Event Logging:**

```ruby
# app/models/security_event.rb
class SecurityEvent < ApplicationRecord
  EVENT_TYPES = %w[
    login_success
    login_failure
    password_reset_requested
    password_reset_completed
    account_locked
    two_factor_enabled
    two_factor_disabled
    unauthorized_access_attempt
    api_rate_limit_exceeded
    suspicious_activity
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }

  scope :security_incidents, -> { where(event_type: %w[unauthorized_access_attempt suspicious_activity]) }
  scope :recent, -> { where('created_at > ?', 24.hours.ago) }
end

# app/services/security_logger.rb
class SecurityLogger
  def self.log(event_type:, user: nil, details: {}, severity: :info)
    SecurityEvent.create!(
      event_type: event_type,
      user: user,
      ip_address: details[:ip_address],
      user_agent: details[:user_agent],
      details: details,
      severity: severity
    )

    Rails.logger.tagged('SECURITY') do
      Rails.logger.send(severity, {
        event_type: event_type,
        user_id: user&.id,
        details: details
      }.to_json)
    end
  end
end

# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      SecurityLogger.log(
        event_type: 'login_success',
        user: user,
        details: { ip_address: request.remote_ip, user_agent: request.user_agent }
      )
      sign_in(user)
      redirect_to root_path
    else
      SecurityLogger.log(
        event_type: 'login_failure',
        user: user,
        details: {
          email: params[:email],
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        },
        severity: :warn
      )
      render :new, alert: 'Invalid credentials'
    end
  end
end
```

**Audit Trail:**

```ruby
# Gemfile
gem 'paper_trail'

# app/models/user.rb
class User < ApplicationRecord
  has_paper_trail on: [:update, :destroy],
    ignore: [:updated_at, :last_sign_in_at],
    meta: {
      ip_address: :current_ip_address,
      user_agent: :current_user_agent
    }

  def current_ip_address
    RequestStore.store[:ip_address]
  end

  def current_user_agent
    RequestStore.store[:user_agent]
  end
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit
  before_action :store_request_metadata

  private

  def store_request_metadata
    RequestStore.store[:ip_address] = request.remote_ip
    RequestStore.store[:user_agent] = request.user_agent
  end
end
```

**Anomaly Detection:**

```ruby
# app/services/anomaly_detector.rb
class AnomalyDetector
  def self.check_suspicious_activity(user)
    # Check for multiple failed logins
    recent_failures = SecurityEvent.where(
      event_type: 'login_failure',
      user: user
    ).where('created_at > ?', 1.hour.ago).count

    if recent_failures > 5
      alert_security_team(user, 'Multiple failed login attempts')
    end

    # Check for login from new location
    if user.current_sign_in_ip != user.last_sign_in_ip
      notify_user(user, 'Login from new location detected')
    end

    # Check for unusual activity patterns
    if unusual_activity?(user)
      require_additional_verification(user)
    end
  end

  private

  def self.unusual_activity?(user)
    # Implement heuristics based on:
    # - Time of day
    # - Geographic location
    # - Device fingerprint
    # - Activity volume
    false
  end
end
```

### Phase 4: API Security

#### Rate Limiting

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  # Throttle login attempts
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.params['email'].to_s.downcase.presence
    end
  end

  # Throttle API requests
  throttle('api/ip', limit: 100, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Block malicious IPs
  blocklist('block bad actors') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 10.minutes, bantime: 1.hour) do
      req.path.start_with?('/api/')
    end
  end

  # Security event logging
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [:throttle, :blocklist].include?(req.env['rack.attack.match_type'])
      SecurityLogger.log(
        event_type: 'api_rate_limit_exceeded',
        details: {
          ip_address: req.ip,
          path: req.path,
          match_type: req.env['rack.attack.match_type']
        },
        severity: :warn
      )
    end
  end
end
```

#### API Authentication

```ruby
# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :authenticate_api_request

    private

    def authenticate_api_request
      authenticate_with_http_token do |token, options|
        @current_api_key = ApiKey.find_by(token: token)
        @current_api_key&.active? && !@current_api_key.expired?
      end || render_unauthorized
    end

    def render_unauthorized
      render json: {
        error: {
          code: 'unauthorized',
          message: 'Invalid or expired API key'
        }
      }, status: :unauthorized
    end
  end
end

# app/models/api_key.rb
class ApiKey < ApplicationRecord
  belongs_to :user

  before_create :generate_token

  scope :active, -> { where(revoked_at: nil) }

  def active?
    revoked_at.nil?
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  def revoke!
    update(revoked_at: Time.current)
  end

  private

  def generate_token
    loop do
      self.token = SecureRandom.urlsafe_base64(32)
      break unless ApiKey.exists?(token: token)
    end
  end
end
```

### Phase 5: File Upload Security

```ruby
# app/models/attachment.rb
class Attachment < ApplicationRecord
  has_one_attached :file

  # Whitelist allowed file types
  ALLOWED_CONTENT_TYPES = %w[
    image/png
    image/jpeg
    image/gif
    application/pdf
  ].freeze

  validates :file,
    presence: true,
    content_type: ALLOWED_CONTENT_TYPES,
    size: { less_than: 10.megabytes }

  # Scan for malware
  before_save :scan_for_malware

  # Generate secure filename
  before_create :sanitize_filename

  private

  def scan_for_malware
    return unless file.attached?

    # Integrate with ClamAV or VirusTotal
    unless MalwareScanner.safe?(file)
      errors.add(:file, 'appears to contain malicious content')
      throw(:abort)
    end
  end

  def sanitize_filename
    return unless file.attached?

    original_filename = file.filename.to_s
    extension = File.extname(original_filename)
    basename = File.basename(original_filename, extension)

    # Remove special characters
    safe_basename = basename.gsub(/[^0-9A-Za-z.\-]/, '_')

    # Prevent directory traversal
    safe_basename = safe_basename.gsub(/\.\./, '_')

    file.filename = "#{safe_basename}#{extension}"
  end
end

# app/services/malware_scanner.rb
class MalwareScanner
  def self.safe?(file)
    # Example using ClamAV
    ClamScan.scan(file.tempfile.path) == :safe
  rescue StandardError => e
    Rails.logger.error("Malware scan failed: #{e.message}")
    false  # Fail closed
  end
end
```

### Phase 6: CSRF Protection

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # For API controllers that use cookie auth
  protect_from_forgery with: :null_session, if: proc { |c| c.request.format == 'application/json' }
end

# For form submissions
# app/views/layouts/application.html.erb
<head>
  <%= csrf_meta_tags %>
</head>

# app/javascript/application.js
// Automatically include CSRF token in AJAX requests
document.addEventListener('DOMContentLoaded', () => {
  const csrfToken = document.querySelector('[name=csrf-token]').content;

  fetch('/api/endpoint', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({ data: 'value' })
  });
});
```

## Best Practices

### 1. Security in Development Workflow

```yaml
# .github/workflows/security.yml
name: Security Checks

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Run Brakeman
        run: |
          gem install brakeman
          brakeman --no-pager

      - name: Run bundler-audit
        run: |
          gem install bundler-audit
          bundle-audit update
          bundle-audit check

      - name: Run RuboCop Security
        run: |
          bundle exec rubocop --only Security
```

### 2. Secure Coding Guidelines

Create a security checklist for PRs:

```markdown
## Security Checklist

- [ ] All user input is validated and sanitized
- [ ] No SQL injection vulnerabilities (use parameterized queries)
- [ ] No XSS vulnerabilities (proper output encoding)
- [ ] Authorization checks on all protected actions
- [ ] No sensitive data in logs
- [ ] CSRF protection enabled
- [ ] Secure session configuration
- [ ] No secrets in code (use credentials/env vars)
- [ ] File uploads validated and scanned
- [ ] Rate limiting on sensitive endpoints
- [ ] Security headers configured
- [ ] Brakeman scan passes
- [ ] Dependency audit passes
```

### 3. Regular Security Reviews

```ruby
# lib/tasks/security.rake
namespace :security do
  desc 'Run all security checks'
  task audit: :environment do
    puts "Running security audit..."

    # Check for vulnerable dependencies
    system('bundle audit check --update')

    # Run Brakeman
    system('brakeman -q')

    # Check for common issues
    puts "\nChecking configuration..."
    check_ssl_configuration
    check_session_configuration
    check_csrf_protection
    check_security_headers

    puts "\n✅ Security audit complete"
  end

  def check_ssl_configuration
    unless Rails.application.config.force_ssl
      puts "⚠️  WARNING: SSL is not enforced in #{Rails.env}"
    end
  end

  def check_session_configuration
    session_options = Rails.application.config.session_options
    unless session_options[:secure]
      puts "⚠️  WARNING: Secure flag not set on session cookies"
    end
  end

  def check_csrf_protection
    # Check if CSRF protection is enabled
    puts "✅ CSRF protection is enabled"
  end

  def check_security_headers
    headers = Rails.application.config.action_dispatch.default_headers
    required_headers = ['X-Frame-Options', 'X-Content-Type-Options', 'X-XSS-Protection']

    required_headers.each do |header|
      unless headers[header]
        puts "⚠️  WARNING: Missing security header: #{header}"
      end
    end
  end
end
```

## Common Mistakes

### 1. Hardcoded Secrets

```ruby
# Bad: Secrets in code
AWS_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE'
DATABASE_PASSWORD = 'mypassword123'

# Good: Use Rails credentials
aws_key = Rails.application.credentials.dig(:aws, :access_key)
db_password = Rails.application.credentials.dig(:database, :password)

# Or environment variables
aws_key = ENV['AWS_ACCESS_KEY']
```

### 2. Logging Sensitive Data

```ruby
# Bad: Logging passwords
Rails.logger.info("User logged in: #{params[:email]} / #{params[:password]}")

# Good: Filter sensitive params
Rails.application.config.filter_parameters += [:password, :token, :api_key]
```

### 3. Using Weak Random Numbers

```ruby
# Bad: Not cryptographically secure
token = rand(1000000)

# Good: Use SecureRandom
token = SecureRandom.urlsafe_base64(32)
```

### 4. Trusting User Input

```ruby
# Bad: No validation
redirect_to params[:redirect_url]

# Good: Validate redirect URLs
def safe_redirect(url)
  return root_path unless url.present?
  return root_path unless url.start_with?('/')

  url
end
```

### 5. Inadequate Error Messages

```ruby
# Bad: Revealing too much
rescue ActiveRecord::RecordNotFound => e
  render json: { error: e.message }, status: 404

# Good: Generic messages in production
rescue ActiveRecord::RecordNotFound => e
  message = Rails.env.production? ? 'Resource not found' : e.message
  render json: { error: message }, status: 404
end
```

## Security Tools and Resources

### Recommended Gems

```ruby
# Gemfile
group :development do
  gem 'brakeman'              # Static analysis security scanner
  gem 'bundler-audit'         # Check for vulnerable dependencies
  gem 'strong_migrations'     # Catch unsafe migrations
end

gem 'secure_headers'          # Security headers
gem 'rack-attack'             # Rate limiting and blocking
gem 'devise'                  # Authentication
gem 'pundit'                  # Authorization
gem 'paper_trail'             # Audit trail
gem 'rotp'                    # Two-factor authentication
```

### External Tools

- **OWASP ZAP**: Web application security scanner
- **Burp Suite**: Web vulnerability scanner
- **Metasploit**: Penetration testing framework
- **Nmap**: Network scanner
- **Wireshark**: Network protocol analyzer

### Resources

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Rails Security Guide: https://guides.rubyonrails.org/security.html
- Brakeman Documentation: https://brakemanscanner.org/docs/
- Secure Headers: https://github.com/github/secure_headers

## Conclusion

Security is not a one-time task but an ongoing process. Regular audits, code reviews, dependency updates, and security training are essential for maintaining a secure Rails application.

Always:
- Use security tools in your CI/CD pipeline
- Keep dependencies up to date
- Follow the principle of least privilege
- Log security events
- Implement defense in depth
- Educate your team on secure coding practices
- Have an incident response plan

Remember: The cost of prevention is always less than the cost of a breach.
