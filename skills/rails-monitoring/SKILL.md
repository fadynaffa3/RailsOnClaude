---
name: rails-monitoring
description: Application monitoring setup for Rails including APM tools, log aggregation, error tracking, uptime monitoring, and performance dashboards. Covers New Relic, Skylight, Datadog, Papertrail, and custom monitoring solutions.
category: monitoring
tags: [monitoring, apm, logging, performance, observability, metrics]
---

# Rails Monitoring

Set up comprehensive monitoring for Ruby on Rails applications in production.

## Use this skill when

- Setting up application monitoring
- Configuring APM (Application Performance Monitoring)
- Setting up log aggregation
- Monitoring uptime and availability
- Tracking performance metrics
- Setting up alerting
- Debugging production issues

## Do not use this skill when

- Setting up error tracking (use sentry or similar)
- Writing application code (use rails-help)
- Optimizing performance (use rails-performance-optimizer)

## Instructions

### Step 1: Choose Monitoring Strategy

**APM Tools:**
- **New Relic** - Full-featured, expensive
- **Skylight** - Rails-focused, affordable
- **Datadog** - Infrastructure + APM
- **Scout APM** - Lightweight, Rails-optimized
- **AppSignal** - All-in-one monitoring

**Log Aggregation:**
- **Papertrail** - Simple, affordable
- **Loggly** - Feature-rich
- **Splunk** - Enterprise
- **CloudWatch Logs** - AWS native
- **Lograge** - Structured logging

**Uptime Monitoring:**
- **Pingdom**
- **UptimeRobot**
- **StatusCake**
- **HealthChecks.io**

### Step 2: Application Performance Monitoring (APM)

**New Relic Setup:**
```ruby
# Gemfile
gem 'newrelic_rpm'

# config/newrelic.yml
common: &default_settings
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: <%= ENV['NEW_RELIC_APP_NAME'] || 'My Rails App' %>
  monitor_mode: true
  log_level: info

  # Transaction tracing
  transaction_tracer:
    enabled: true
    transaction_threshold: apdex_f
    record_sql: obfuscated
    stack_trace_threshold: 0.5

  # Error collection
  error_collector:
    enabled: true
    ignore_errors: "ActionController::RoutingError"

  # Browser monitoring
  browser_monitoring:
    auto_instrument: true

development:
  <<: *default_settings
  monitor_mode: false

production:
  <<: *default_settings
  monitor_mode: true
```

**Skylight Setup:**
```ruby
# Gemfile
gem 'skylight'

# config/skylight.yml
authentication: <%= ENV['SKYLIGHT_AUTHENTICATION'] %>
```

**Custom Instrumentation:**
```ruby
# Instrument specific methods
class UserService
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

  def process_order(order)
    # Business logic
  end
  add_transaction_tracer :process_order, category: :task
end

# Custom metrics
NewRelic::Agent.record_metric('Custom/Orders/Processing', order_count)

# Custom events
NewRelic::Agent.record_custom_event('OrderPlaced', {
  order_id: order.id,
  amount: order.total,
  customer_id: order.customer_id
})
```

### Step 3: Structured Logging with Lograge

**Setup Lograge:**
```ruby
# Gemfile
gem 'lograge'

# config/environments/production.rb
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    {
      time: event.time,
      remote_ip: event.payload[:remote_ip],
      user_id: event.payload[:user_id],
      request_id: event.payload[:request_id]
    }
  end

  # Exclude health check endpoints
  config.lograge.ignore_actions = ['HealthController#index']
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :append_info_to_payload

  def append_info_to_payload(payload)
    super
    payload[:remote_ip] = request.remote_ip
    payload[:user_id] = current_user&.id
    payload[:request_id] = request.uuid
  end
end
```

**Custom Log Formatting:**
```ruby
# config/initializers/logging.rb
class CustomLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    {
      timestamp: timestamp.iso8601,
      severity: severity,
      message: msg,
      environment: Rails.env,
      hostname: Socket.gethostname
    }.to_json + "\n"
  end
end

Rails.logger = CustomLogger.new(STDOUT)
```

### Step 4: Log Aggregation

**Papertrail Setup:**
```ruby
# Gemfile
gem 'remote_syslog_logger'

# config/environments/production.rb
Rails.application.configure do
  config.logger = RemoteSyslogLogger.new(
    ENV['PAPERTRAIL_HOST'],
    ENV['PAPERTRAIL_PORT'],
    program: "rails-#{Rails.env}"
  )
end
```

**CloudWatch Logs (AWS):**
```ruby
# Gemfile
gem 'aws-sdk-cloudwatchlogs'

# config/initializers/cloudwatch_logger.rb
if Rails.env.production?
  require 'cloudwatch_logger'

  Rails.logger = CloudWatchLogger.new(
    ENV['AWS_ACCESS_KEY_ID'],
    ENV['AWS_SECRET_ACCESS_KEY'],
    ENV['AWS_REGION'],
    ENV['CLOUDWATCH_LOG_GROUP']
  )
end
```

**Lograge + Elasticsearch:**
```ruby
# config/environments/production.rb
config.lograge.formatter = Lograge::Formatters::Logstash.new

# Outputs JSON that Logstash/Elasticsearch can parse
# Use Filebeat or Logstash to ship logs
```

### Step 5: Custom Metrics

**StatsD Integration:**
```ruby
# Gemfile
gem 'statsd-instrument'

# config/initializers/statsd.rb
StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new(
  ENV['STATSD_HOST'] || 'localhost',
  ENV['STATSD_PORT'] || 8125
)

# Usage in code
class OrdersController < ApplicationController
  def create
    StatsD.increment('orders.created')
    StatsD.measure('orders.creation_time') do
      @order = Order.create!(order_params)
    end

    StatsD.gauge('orders.total_value', @order.total)

    render json: @order
  end
end
```

**Prometheus Metrics:**
```ruby
# Gemfile
gem 'prometheus-client'

# config/initializers/prometheus.rb
require 'prometheus/client'
require 'prometheus/client/push'

Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(
  dir: Rails.root.join('tmp', 'prometheus')
)

# app/middleware/prometheus_middleware.rb
class PrometheusMiddleware
  def initialize(app)
    @app = app
    @registry = Prometheus::Client.registry
    @requests = @registry.counter(
      :http_requests_total,
      docstring: 'Total HTTP requests',
      labels: [:method, :path, :status]
    )
    @duration = @registry.histogram(
      :http_request_duration_seconds,
      docstring: 'HTTP request duration',
      labels: [:method, :path]
    )
  end

  def call(env)
    start = Time.now
    status, headers, body = @app.call(env)
    duration = Time.now - start

    @requests.increment(
      labels: {
        method: env['REQUEST_METHOD'],
        path: env['PATH_INFO'],
        status: status
      }
    )

    @duration.observe(
      duration,
      labels: {
        method: env['REQUEST_METHOD'],
        path: env['PATH_INFO']
      }
    )

    [status, headers, body]
  end
end

# config/application.rb
config.middleware.use PrometheusMiddleware

# Expose metrics endpoint
# config/routes.rb
get '/metrics', to: proc { |env|
  [200, {'Content-Type' => 'text/plain'}, [Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)]]
}
```

### Step 6: Health Checks

**Basic Health Check:**
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate!

  def index
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version
    }
  end

  def detailed
    checks = {
      database: check_database,
      redis: check_redis,
      sidekiq: check_sidekiq
    }

    status = checks.values.all? { |c| c[:status] == 'ok' } ? 'ok' : 'error'

    render json: {
      status: status,
      checks: checks,
      timestamp: Time.current.iso8601
    }, status: status == 'ok' ? :ok : :service_unavailable
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'ok' }
  rescue => e
    { status: 'error', message: e.message }
  end

  def check_redis
    Redis.current.ping
    { status: 'ok' }
  rescue => e
    { status: 'error', message: e.message }
  end

  def check_sidekiq
    stats = Sidekiq::Stats.new
    {
      status: 'ok',
      queues: stats.queues,
      processed: stats.processed,
      failed: stats.failed
    }
  rescue => e
    { status: 'error', message: e.message }
  end
end

# config/routes.rb
get '/health', to: 'health#index'
get '/health/detailed', to: 'health#detailed'
```

### Step 7: Uptime Monitoring

**Configure monitoring service:**
```yaml
# Pingdom configuration
- Endpoint: https://yourapp.com/health
- Check interval: 1 minute
- Alert contacts: team@example.com, #alerts-channel

# UptimeRobot configuration
- Monitor Type: HTTP(s)
- URL: https://yourapp.com/health
- Monitoring Interval: 5 minutes
- Alert Contacts: Email, Slack webhook
```

**Custom uptime checker:**
```ruby
# lib/tasks/uptime_check.rake
namespace :uptime do
  desc 'Check application uptime and report'
  task check: :environment do
    begin
      response = Net::HTTP.get_response(URI(ENV['APP_URL'] + '/health'))

      if response.code == '200'
        puts "✅ Application is up"
        StatsD.increment('uptime.check.success')
      else
        puts "❌ Application returned #{response.code}"
        StatsD.increment('uptime.check.failure')
        alert_team("Application health check failed: #{response.code}")
      end
    rescue => e
      puts "❌ Application is down: #{e.message}"
      StatsD.increment('uptime.check.error')
      alert_team("Application is down: #{e.message}")
    end
  end

  def alert_team(message)
    SlackNotifier.notify(
      channel: '#alerts',
      text: message,
      username: 'Uptime Monitor'
    )
  end
end
```

### Step 8: Performance Dashboards

**Grafana Dashboard (with Prometheus):**
```yaml
# docker-compose.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

# prometheus.yml
scrape_configs:
  - job_name: 'rails'
    static_configs:
      - targets: ['rails:3000']
    metrics_path: '/metrics'
```

**Key Metrics to Track:**
```ruby
# Custom dashboard metrics
class MetricsCollector
  def self.collect
    {
      # Application metrics
      'app.requests.total': total_requests,
      'app.requests.rate': requests_per_second,
      'app.response_time.avg': average_response_time,
      'app.response_time.p95': p95_response_time,

      # Database metrics
      'db.connections.active': active_connections,
      'db.queries.slow': slow_queries_count,
      'db.size': database_size_mb,

      # Background jobs
      'jobs.enqueued': Sidekiq::Stats.new.enqueued,
      'jobs.processed': Sidekiq::Stats.new.processed,
      'jobs.failed': Sidekiq::Stats.new.failed,

      # Business metrics
      'users.active': User.active.count,
      'orders.today': Order.where(created_at: Time.current.all_day).count,
      'revenue.today': Order.where(created_at: Time.current.all_day).sum(:total)
    }
  end
end
```

### Step 9: Alerting

**Configure Alerts:**
```ruby
# lib/alerting/threshold_monitor.rb
class ThresholdMonitor
  THRESHOLDS = {
    error_rate: 0.05,        # 5% error rate
    response_time: 1000,     # 1000ms
    database_connections: 20, # 20 active connections
    job_queue_size: 1000     # 1000 jobs in queue
  }

  def self.check_all
    check_error_rate
    check_response_time
    check_database_connections
    check_job_queue
  end

  def self.check_error_rate
    rate = calculate_error_rate
    if rate > THRESHOLDS[:error_rate]
      alert(
        "High error rate: #{(rate * 100).round(2)}%",
        severity: :critical
      )
    end
  end

  def self.check_response_time
    avg_time = calculate_avg_response_time
    if avg_time > THRESHOLDS[:response_time]
      alert(
        "High response time: #{avg_time}ms",
        severity: :warning
      )
    end
  end

  private

  def self.alert(message, severity:)
    SlackNotifier.notify(
      channel: severity == :critical ? '#critical-alerts' : '#alerts',
      text: message,
      color: severity == :critical ? 'danger' : 'warning'
    )

    PagerDuty.trigger(message) if severity == :critical
  end
end

# Schedule checks
# config/schedule.rb (whenever gem)
every 1.minute do
  runner "ThresholdMonitor.check_all"
end
```

### Step 10: Performance Profiling

**Rack Mini Profiler:**
```ruby
# Gemfile
gem 'rack-mini-profiler'

# config/initializers/rack_profiler.rb
if Rails.env.development?
  require 'rack-mini-profiler'

  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.position = 'bottom-right'
  Rack::MiniProfiler.config.start_hidden = false
end
```

**Memory Profiler:**
```ruby
# Gemfile
gem 'memory_profiler'

# In console or controller
report = MemoryProfiler.report do
  # Code to profile
  User.includes(:posts).limit(100).to_a
end

report.pretty_print
```

**Flamegraphs:**
```ruby
# Gemfile
gem 'stackprof'
gem 'flamegraph'

# Profile endpoint
def profile_action
  StackProf.run(mode: :cpu, out: 'tmp/stackprof-cpu.dump') do
    # Code to profile
  end
end

# Generate flamegraph
# stackprof tmp/stackprof-cpu.dump --flamegraph > tmp/flamegraph.html
```

## Best Practices

### Monitoring Strategy

1. **Layered Approach:**
   - Application layer (APM)
   - Infrastructure layer (server metrics)
   - Business layer (KPIs)

2. **Alert Fatigue Prevention:**
   - Set meaningful thresholds
   - Use severity levels
   - Aggregate similar alerts
   - Implement on-call rotation

3. **Documentation:**
   - Runbook for each alert
   - Escalation procedures
   - Dashboard locations
   - Contact information

### Log Management

1. **Structured Logging:**
   - Use JSON format
   - Include context (user_id, request_id)
   - Consistent field names

2. **Log Levels:**
   - DEBUG: Development only
   - INFO: Normal operations
   - WARN: Degraded functionality
   - ERROR: Failures requiring attention
   - FATAL: System crashes

3. **Retention:**
   - Recent logs: 7-30 days (hot storage)
   - Historical logs: 1-2 years (cold storage)
   - Compliance requirements

### Metrics Collection

1. **RED Metrics:**
   - Rate: Requests per second
   - Errors: Error rate
   - Duration: Response time

2. **USE Metrics:**
   - Utilization: Resource usage %
   - Saturation: Queue depth
   - Errors: Error count

3. **Business Metrics:**
   - User signups
   - Orders placed
   - Revenue
   - Conversion rates

## Common Mistakes to Avoid

- ❌ No monitoring until production issues occur
- ❌ Monitoring everything without priorities
- ❌ Ignoring alert fatigue
- ❌ No runbooks for alerts
- ❌ Logging sensitive data (passwords, tokens)
- ❌ Not correlating logs with metrics
- ❌ Insufficient log retention
- ❌ No health check endpoints
- ❌ Monitoring without action plans
- ❌ Neglecting business metrics
