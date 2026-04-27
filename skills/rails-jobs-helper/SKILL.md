---
name: rails-jobs-helper
description: Sidekiq/Solid Queue patterns, retry strategies, job monitoring, error handling, and background job best practices for Rails applications
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - background-jobs
  - sidekiq
  - solid-queue
  - async
  - workers
dependencies:
  - rails >= 7.0
  - sidekiq or solid_queue
---

# Rails Jobs Helper

A comprehensive guide for building robust, scalable background job systems in Rails using Sidekiq or Solid Queue. This skill covers job patterns, retry strategies, error handling, monitoring, and performance optimization.

## Use this skill when

- Setting up background job processing
- Moving slow operations out of request cycles
- Implementing retry logic for failed jobs
- Handling job errors and failures
- Setting up job monitoring and alerts
- Optimizing job performance
- Processing large datasets asynchronously
- Implementing scheduled/recurring jobs
- Building job chains and workflows
- Handling job priorities and queues
- Implementing idempotent jobs
- Setting up job rate limiting
- Dealing with job timeouts
- Creating job dashboards
- Migrating between job backends

## Do not use this skill when

- Operations are fast enough to run synchronously
- Real-time bidirectional communication is needed (use Action Cable)
- The task requires immediate user feedback
- You're dealing with simple cron jobs (use system cron)

## Prerequisites

- Rails 7.0+ application
- Redis installed (for Sidekiq) or PostgreSQL (for Solid Queue)
- Understanding of asynchronous processing
- Familiarity with Rails Active Job

## Comparing Job Backends

### Solid Queue (Rails 8 Default)

**Pros:**
- Native Rails integration
- Uses existing PostgreSQL database
- No additional infrastructure
- ACID guarantees
- Built-in dashboard

**Cons:**
- Database load
- Less mature than Sidekiq
- Fewer features

```ruby
# Gemfile
gem 'solid_queue'

# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 5
      processes: 3
      polling_interval: 0.1
```

### Sidekiq

**Pros:**
- Battle-tested and mature
- Excellent performance
- Rich ecosystem
- Web UI with detailed stats
- Enterprise features available

**Cons:**
- Requires Redis
- Additional infrastructure
- Enterprise version is paid

```ruby
# Gemfile
gem 'sidekiq'
gem 'sidekiq-scheduler'  # For recurring jobs
gem 'sidekiq-unique-jobs' # For job uniqueness

# config/sidekiq.yml
:concurrency: 25
:queues:
  - critical
  - default
  - low_priority
:max_retries: 3
```

## Step-by-Step Implementation

### Step 1: Install and Configure

#### Sidekiq Setup

```ruby
# Gemfile
gem 'sidekiq'
gem 'redis'

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'], network_timeout: 5 }

  # Enable periodic jobs
  config.on(:startup) do
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], network_timeout: 5 }
end

# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

#### Solid Queue Setup

```ruby
# Gemfile
gem 'solid_queue'

# Install migrations
rails solid_queue:install:migrations
rails db:migrate

# config/application.rb
config.active_job.queue_adapter = :solid_queue

# config/queue.yml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: critical,default,low_priority
      threads: 5
      processes: 3
```

### Step 2: Create Basic Jobs

```ruby
# app/jobs/user_welcome_job.rb
class UserWelcomeJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome_email(user).deliver_now
  end
end

# Usage
UserWelcomeJob.perform_later(user.id)
UserWelcomeJob.set(wait: 1.hour).perform_later(user.id)
UserWelcomeJob.set(wait_until: Date.tomorrow.noon).perform_later(user.id)
UserWelcomeJob.set(queue: :critical).perform_later(user.id)
```

### Step 3: Implement Retry Logic

```ruby
# app/jobs/resilient_job.rb
class ResilientJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  retry_on Net::OpenTimeout, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::RecordNotUnique, attempts: 0 # Don't retry

  # Discard configuration
  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.error("Job discarded: #{error.message}")
    ErrorTracker.notify(error, job: job)
  end

  # Custom retry logic
  retry_on CustomApiError, wait: ->(executions) {
    case executions
    when 1 then 30.seconds
    when 2 then 5.minutes
    when 3 then 30.minutes
    else 2.hours
    end
  }

  def perform(user_id)
    user = User.find(user_id)
    # Job logic
  rescue SomeError => e
    # Conditional retry
    if executions < 3
      retry_job wait: 5.minutes
    else
      ErrorTracker.notify(e, user_id: user_id)
      raise
    end
  end
end
```

### Step 4: Error Handling

```ruby
# app/jobs/concerns/error_handling.rb
module ErrorHandling
  extend ActiveSupport::Concern

  included do
    around_perform :handle_errors
  end

  private

  def handle_errors
    yield
  rescue StandardError => e
    handle_job_error(e)
    raise # Re-raise to trigger retry logic
  end

  def handle_job_error(error)
    Rails.logger.error({
      job_class: self.class.name,
      job_id: job_id,
      error_class: error.class.name,
      error_message: error.message,
      backtrace: error.backtrace.first(5)
    }.to_json)

    ErrorTracker.notify(error, context: {
      job_class: self.class.name,
      job_id: job_id,
      arguments: arguments,
      executions: executions
    })
  end
end

# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  include ErrorHandling

  # Global job configuration
  queue_as :default

  # Track job duration
  around_perform :track_duration

  private

  def track_duration
    start_time = Time.current
    yield
    duration = Time.current - start_time

    Rails.logger.info({
      job_class: self.class.name,
      duration_seconds: duration.round(2)
    }.to_json)
  end
end
```

### Step 5: Queue Management

```ruby
# app/jobs/prioritized_job.rb
class PrioritizedJob < ApplicationJob
  # Define queue priorities
  queue_with_priority 10 # Higher number = higher priority

  def perform(data)
    # Job logic
  end
end

# config/sidekiq.yml
:queues:
  - [critical, 2]    # Process 2x more from critical queue
  - [default, 1]
  - [low_priority, 1]

# Dynamic queue selection
class AdaptiveJob < ApplicationJob
  def perform(user_id, options = {})
    queue_name = determine_queue(user_id, options)
    self.class.set(queue: queue_name).perform_later(user_id, options)
  end

  private

  def determine_queue(user_id, options)
    return :critical if options[:urgent]

    user = User.find(user_id)
    user.premium? ? :default : :low_priority
  end
end
```

### Step 6: Idempotent Jobs

```ruby
# app/jobs/idempotent_job.rb
class IdempotentJob < ApplicationJob
  queue_as :default

  # Ensure job runs only once with same arguments
  def perform(user_id, order_id)
    idempotency_key = "#{self.class.name}:#{user_id}:#{order_id}"

    # Try to acquire lock
    lock_acquired = Rails.cache.write(
      idempotency_key,
      true,
      unless_exist: true,
      expires_in: 24.hours
    )

    return unless lock_acquired

    begin
      # Job logic here
      process_order(user_id, order_id)
    ensure
      # Keep lock for 24 hours to prevent re-execution
    end
  end

  private

  def process_order(user_id, order_id)
    # Idempotent processing
  end
end

# Using sidekiq-unique-jobs gem
class UniqueJob < ApplicationJob
  sidekiq_options lock: :until_executed,
                   on_conflict: :log

  def perform(user_id)
    # Only one instance of this job per user_id will run
  end
end
```

### Step 7: Batch Processing

```ruby
# app/jobs/batch_import_job.rb
class BatchImportJob < ApplicationJob
  queue_as :default

  def perform(batch_data, batch_number, total_batches)
    Rails.logger.info("Processing batch #{batch_number}/#{total_batches}")

    User.insert_all!(batch_data) if batch_data.any?

    # Track progress
    increment_progress(batch_number, total_batches)

    # Trigger completion job if last batch
    if batch_number == total_batches
      ImportCompletionJob.perform_later
    end
  end

  private

  def increment_progress(current, total)
    progress = (current.to_f / total * 100).round(2)
    Rails.cache.write('import_progress', progress, expires_in: 1.hour)
  end
end

# app/services/batch_importer.rb
class BatchImporter
  BATCH_SIZE = 1000

  def self.import(data)
    batches = data.each_slice(BATCH_SIZE).to_a
    total_batches = batches.size

    batches.each_with_index do |batch, index|
      BatchImportJob.perform_later(batch, index + 1, total_batches)
    end
  end
end
```

### Step 8: Job Chains and Workflows

```ruby
# app/jobs/workflow_job.rb
class WorkflowJob < ApplicationJob
  queue_as :default

  def perform(step, data = {})
    case step
    when :start
      result = perform_step_1(data)
      WorkflowJob.perform_later(:step2, result)
    when :step2
      result = perform_step_2(data)
      WorkflowJob.perform_later(:step3, result)
    when :step3
      perform_final_step(data)
    end
  end

  private

  def perform_step_1(data)
    # Step 1 logic
    data.merge(step1_result: 'complete')
  end

  def perform_step_2(data)
    # Step 2 logic
    data.merge(step2_result: 'complete')
  end

  def perform_final_step(data)
    # Final step logic
    NotificationJob.perform_later('Workflow complete', data)
  end
end

# Using callbacks for chaining
class ChainedJob < ApplicationJob
  after_perform do |job|
    NextJob.perform_later(job.arguments.first)
  end

  def perform(user_id)
    # Job logic
  end
end
```

### Step 9: Scheduled/Recurring Jobs

#### Using Sidekiq Scheduler

```ruby
# Gemfile
gem 'sidekiq-scheduler'

# config/sidekiq_scheduler.yml
daily_cleanup:
  cron: '0 2 * * *' # Every day at 2 AM
  class: DailyCleanupJob
  queue: maintenance

hourly_sync:
  every: '1h'
  class: HourlySyncJob
  queue: default

weekly_report:
  cron: '0 9 * * 1' # Every Monday at 9 AM
  class: WeeklyReportJob
  args:
    - report_type: 'weekly'
```

#### Using Solid Queue

```ruby
# config/recurring.yml
production:
  daily_cleanup:
    class: DailyCleanupJob
    schedule: every day at 2am
    queue: maintenance

  hourly_sync:
    class: HourlySyncJob
    schedule: every hour
    queue: default
```

### Step 10: Job Monitoring

```ruby
# app/services/job_monitor.rb
class JobMonitor
  def self.check_queue_health
    stats = Sidekiq::Stats.new

    alerts = []
    alerts << "High queue size: #{stats.enqueued}" if stats.enqueued > 10000
    alerts << "High retry size: #{stats.retry_size}" if stats.retry_size > 1000
    alerts << "High dead job count: #{stats.dead_size}" if stats.dead_size > 100

    if alerts.any?
      SlackNotifier.notify(
        channel: '#alerts',
        text: "Job Queue Alerts:\n#{alerts.join("\n")}"
      )
    end
  end

  def self.job_statistics
    stats = Sidekiq::Stats.new
    {
      enqueued: stats.enqueued,
      scheduled: stats.scheduled_size,
      retry: stats.retry_size,
      dead: stats.dead_size,
      processed: stats.processed,
      failed: stats.failed,
      processes: stats.processes_size,
      busy: stats.workers_size
    }
  end
end

# Schedule monitoring job
class JobHealthCheckJob < ApplicationJob
  queue_as :critical

  def perform
    JobMonitor.check_queue_health
  end
end
```

## Advanced Patterns

### 1. Job Throttling

```ruby
# app/jobs/throttled_job.rb
class ThrottledJob < ApplicationJob
  queue_as :default

  THROTTLE_LIMIT = 10
  THROTTLE_PERIOD = 1.minute

  def perform(user_id)
    throttle_key = "throttle:#{self.class.name}:#{user_id}"

    # Check current count
    current_count = Rails.cache.read(throttle_key) || 0

    if current_count >= THROTTLE_LIMIT
      # Reschedule for later
      self.class.set(wait: THROTTLE_PERIOD).perform_later(user_id)
      return
    end

    # Increment counter
    Rails.cache.increment(throttle_key, 1, expires_in: THROTTLE_PERIOD)

    # Perform job
    process_user(user_id)
  end

  private

  def process_user(user_id)
    # Job logic
  end
end
```

### 2. Job with Progress Tracking

```ruby
# app/jobs/progress_trackable_job.rb
class ProgressTrackableJob < ApplicationJob
  queue_as :default

  def perform(total_items, batch_id)
    progress_key = "job_progress:#{batch_id}"

    total_items.times do |i|
      # Process item
      process_item(i)

      # Update progress
      progress = ((i + 1).to_f / total_items * 100).round(2)
      Rails.cache.write(progress_key, {
        progress: progress,
        current: i + 1,
        total: total_items,
        updated_at: Time.current
      }, expires_in: 1.hour)
    end
  end

  def self.get_progress(batch_id)
    Rails.cache.read("job_progress:#{batch_id}") || { progress: 0, current: 0, total: 0 }
  end

  private

  def process_item(index)
    # Item processing logic
    sleep 0.1 # Simulate work
  end
end

# app/controllers/jobs_controller.rb
class JobsController < ApplicationController
  def progress
    batch_id = params[:batch_id]
    progress = ProgressTrackableJob.get_progress(batch_id)

    render json: progress
  end
end
```

### 3. Circuit Breaker Pattern

```ruby
# app/jobs/circuit_breaker_job.rb
class CircuitBreakerJob < ApplicationJob
  queue_as :default

  FAILURE_THRESHOLD = 5
  TIMEOUT_DURATION = 5.minutes

  def perform(api_name, data)
    circuit_key = "circuit_breaker:#{api_name}"

    # Check circuit state
    if circuit_open?(circuit_key)
      Rails.logger.warn("Circuit breaker open for #{api_name}, skipping job")
      self.class.set(wait: TIMEOUT_DURATION).perform_later(api_name, data)
      return
    end

    begin
      # Call external API
      result = call_external_api(api_name, data)

      # Reset failure count on success
      Rails.cache.delete(circuit_key)

      result
    rescue StandardError => e
      # Increment failure count
      increment_failures(circuit_key)

      raise
    end
  end

  private

  def circuit_open?(key)
    failures = Rails.cache.read(key) || 0
    failures >= FAILURE_THRESHOLD
  end

  def increment_failures(key)
    Rails.cache.increment(key, 1, expires_in: TIMEOUT_DURATION)
  end

  def call_external_api(api_name, data)
    # API call logic
  end
end
```

### 4. Job Deduplication

```ruby
# app/jobs/deduplicated_job.rb
class DeduplicatedJob < ApplicationJob
  queue_as :default

  def perform(user_id, action)
    dedup_key = "dedup:#{self.class.name}:#{user_id}:#{action}"

    # Check if job already processed recently
    if Rails.cache.exist?(dedup_key)
      Rails.logger.info("Skipping duplicate job: #{dedup_key}")
      return
    end

    # Perform job
    result = perform_action(user_id, action)

    # Mark as processed
    Rails.cache.write(dedup_key, true, expires_in: 5.minutes)

    result
  end

  private

  def perform_action(user_id, action)
    # Job logic
  end
end
```

### 5. Parent-Child Job Pattern

```ruby
# app/jobs/parent_job.rb
class ParentJob < ApplicationJob
  queue_as :default

  def perform(item_ids)
    parent_job_id = job_id

    # Initialize tracking
    Rails.cache.write("parent_job:#{parent_job_id}", {
      total: item_ids.size,
      completed: 0,
      failed: 0
    }, expires_in: 1.hour)

    # Spawn child jobs
    item_ids.each do |item_id|
      ChildJob.perform_later(item_id, parent_job_id)
    end
  end
end

# app/jobs/child_job.rb
class ChildJob < ApplicationJob
  queue_as :default

  after_perform :update_parent_progress

  def perform(item_id, parent_job_id)
    @parent_job_id = parent_job_id

    # Process item
    process_item(item_id)
  rescue StandardError => e
    increment_parent_failed
    raise
  end

  private

  def process_item(item_id)
    # Item processing logic
  end

  def update_parent_progress
    parent_key = "parent_job:#{@parent_job_id}"
    parent_data = Rails.cache.read(parent_key)

    return unless parent_data

    parent_data[:completed] += 1

    Rails.cache.write(parent_key, parent_data, expires_in: 1.hour)

    # Trigger completion job if all done
    if parent_data[:completed] + parent_data[:failed] == parent_data[:total]
      ParentCompletionJob.perform_later(@parent_job_id, parent_data)
    end
  end

  def increment_parent_failed
    parent_key = "parent_job:#{@parent_job_id}"
    parent_data = Rails.cache.read(parent_key)

    return unless parent_data

    parent_data[:failed] += 1
    Rails.cache.write(parent_key, parent_data, expires_in: 1.hour)
  end
end
```

## Best Practices

### 1. Keep Jobs Small and Focused

```ruby
# Bad: Job does too much
class DoEverythingJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    user.update_profile
    user.send_email
    user.sync_to_crm
    user.update_analytics
    user.notify_team
  end
end

# Good: Separate concerns
class UpdateProfileJob < ApplicationJob
  def perform(user_id)
    User.find(user_id).update_profile
  end
end

class SendEmailJob < ApplicationJob
  def perform(user_id)
    User.find(user_id).send_email
  end
end
```

### 2. Use Job Arguments Properly

```ruby
# Bad: Passing entire objects
UserJob.perform_later(user)

# Good: Pass IDs
UserJob.perform_later(user.id)

# Good: Pass primitive values
UserJob.perform_later(user_id: user.id, action: 'update')
```

### 3. Handle Missing Records Gracefully

```ruby
class SafeJob < ApplicationJob
  retry_on ActiveRecord::RecordNotFound, attempts: 1 do |job, error|
    Rails.logger.warn("Record not found for job #{job.class.name}: #{error.message}")
  end

  def perform(user_id)
    user = User.find(user_id)
    process_user(user)
  rescue ActiveRecord::RecordNotFound => e
    # Log and move on
    Rails.logger.warn("User #{user_id} not found, skipping job")
  end
end
```

### 4. Use Appropriate Queue Names

```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  QUEUE_PRIORITIES = {
    critical: 1,    # User-facing, must be fast
    default: 2,     # Normal background work
    low: 3,         # Cleanup, reports
    mailers: 4      # Emails, notifications
  }.freeze
end

# Usage
class CriticalJob < ApplicationJob
  queue_as :critical
end

class ReportJob < ApplicationJob
  queue_as :low
end
```

### 5. Implement Proper Logging

```ruby
class LoggableJob < ApplicationJob
  before_perform do |job|
    Rails.logger.info("Starting job: #{job.class.name} with args: #{job.arguments.inspect}")
  end

  after_perform do |job|
    Rails.logger.info("Completed job: #{job.class.name}")
  end

  around_perform do |job, block|
    start_time = Time.current
    block.call
    duration = Time.current - start_time

    Rails.logger.info({
      job_class: job.class.name,
      duration_seconds: duration.round(2),
      queue_name: job.queue_name,
      job_id: job.job_id
    }.to_json)
  end
end
```

## Common Mistakes

### 1. Not Making Jobs Idempotent

```ruby
# Bad: Not idempotent
class BadJob < ApplicationJob
  def perform(user_id)
    User.find(user_id).increment!(:login_count)
  end
end

# Good: Idempotent
class GoodJob < ApplicationJob
  def perform(user_id, session_id)
    # Use unique session_id to prevent double counting
    cache_key = "login_counted:#{user_id}:#{session_id}"

    return if Rails.cache.exist?(cache_key)

    User.find(user_id).increment!(:login_count)
    Rails.cache.write(cache_key, true, expires_in: 24.hours)
  end
end
```

### 2. Not Handling Timeouts

```ruby
# Bad: No timeout handling
class LongRunningJob < ApplicationJob
  def perform(user_id)
    # Might run forever
    external_api.process(user_id)
  end
end

# Good: With timeout
class TimeoutSafeJob < ApplicationJob
  def perform(user_id)
    Timeout.timeout(30.seconds) do
      external_api.process(user_id)
    end
  rescue Timeout::Error
    Rails.logger.error("Job timed out for user #{user_id}")
    retry_job wait: 1.hour
  end
end
```

### 3. Ignoring Job Failures

```ruby
# Bad: Silent failures
class SilentFailureJob < ApplicationJob
  def perform(user_id)
    process_user(user_id)
  rescue StandardError
    # Swallowed error - bad!
  end
end

# Good: Proper error handling
class ProperErrorHandlingJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(user_id)
    process_user(user_id)
  rescue StandardError => e
    ErrorTracker.notify(e, user_id: user_id)
    raise # Re-raise for retry logic
  end
end
```

### 4. Loading Too Much Data

```ruby
# Bad: Loading everything into memory
class BadBatchJob < ApplicationJob
  def perform
    User.all.each do |user|
      process_user(user)
    end
  end
end

# Good: Batch processing
class GoodBatchJob < ApplicationJob
  def perform
    User.find_each(batch_size: 1000) do |user|
      process_user(user)
    end
  end
end
```

## Testing Background Jobs

```ruby
# spec/jobs/user_welcome_job_spec.rb
require 'rails_helper'

RSpec.describe UserWelcomeJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }

    it 'sends welcome email' do
      expect {
        described_class.perform_now(user.id)
      }.to have_enqueued_mail(UserMailer, :welcome_email)
    end

    it 'handles missing users gracefully' do
      expect {
        described_class.perform_now(99999)
      }.not_to raise_error
    end

    context 'with retries' do
      before do
        allow(UserMailer).to receive(:welcome_email).and_raise(Net::SMTPServerBusy)
      end

      it 'retries on SMTP errors' do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(user.id)
          }
        }.to raise_error(Net::SMTPServerBusy)

        expect(enqueued_jobs.size).to be > 0
      end
    end
  end
end
```

## Conclusion

Building robust background job systems requires:

1. **Proper error handling** - Retry logic and graceful degradation
2. **Idempotency** - Jobs should be safe to run multiple times
3. **Monitoring** - Track job performance and failures
4. **Testing** - Test jobs thoroughly including failure scenarios
5. **Performance** - Batch processing and efficient queries
6. **Observability** - Logging and metrics
7. **Graceful degradation** - Handle missing data and API failures

Remember: Background jobs are critical infrastructure. Treat them with the same care as your main application code.
