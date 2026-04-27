# RailsOnClaude 🛤️

> A curated collection of 18 AI assistant skills for Ruby on Rails development with Claude Code, Cursor, and other AI coding tools.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Quick Start

### Install via NPX (Recommended)

```bash
# Install all skills
npx skills add fadynaffa3/RailsOnClaude

# Or install individual skills
npx skills add fadynaffa3/RailsOnClaude/skills/rails-audit
npx skills add fadynaffa3/RailsOnClaude/skills/rails-dead-code-finder
npx skills add fadynaffa3/RailsOnClaude/skills/ruby-help
npx skills add fadynaffa3/RailsOnClaude/skills/rails-help
```

### Install Manually

```bash
# Clone the repository
git clone https://github.com/fadynaffa3/RailsOnClaude.git
cd RailsOnClaude

# Copy all skills to Claude Code (global)
cp -r skills/* ~/.claude/skills/

# Or copy to project-specific location
cp -r skills/* /path/to/your/rails/project/.agents/skills/
```

### Install Individual Skills

```bash
# Install only the rails audit skill
cp -r skills/rails-audit ~/.claude/skills/

# Install only the dead code finder skill
cp -r skills/rails-dead-code-finder ~/.claude/skills/

# Install only Ruby help skill
cp -r skills/ruby-help ~/.claude/skills/

# Install only Rails help skill
cp -r skills/rails-help ~/.claude/skills/
```

### Usage

**In Claude Code session:**
```
# Code Quality & Auditing
/rails-audit                     # Run comprehensive Rails audit with SimpleCov + RubyCritic
/rails-code-reviewer             # Automated code review for SOLID principles
/rails-dead-code-finder          # Find and remove unused code

# Testing & Performance
/rails-test-helper               # RSpec and testing best practices
/rails-db-optimizer              # Database optimization and index management
/rails-performance-optimizer     # Application performance tuning

# Security & API
/rails-security-audit            # Security vulnerability scanning
/rails-api-designer              # RESTful API design patterns

# DevOps & Infrastructure
/rails-docker                    # Docker and Docker Compose setup
/rails-dip                       # Dip workflow configuration
/rails-monitoring                # APM and logging setup

# Background Jobs & Frontend
/rails-jobs-helper               # Sidekiq/Solid Queue patterns
/rails-turbo-stimulus            # Hotwire integration

# Documentation & Architecture
/rails-docs-generator            # Generate API documentation
/rails-packwerk                  # Modular architecture with Packwerk
/rails-refactoring-guide         # Code refactoring patterns

# Language Expertise
/ruby-help                       # Ruby idioms and metaprogramming
/rails-help                      # Rails conventions and best practices
```

## 📦 What's Inside

This collection includes 18 battle-tested skills organized into 11 categories:

- **Code Quality & Auditing** (3) - Comprehensive audits, automated code review, dead code detection
- **Testing** (1) - RSpec/Minitest patterns, FactoryBot, test coverage analysis
- **Database & Performance** (2) - Query optimization, index management, caching strategies
- **Security** (1) - Vulnerability scanning, OWASP compliance, secure coding patterns
- **API & Architecture** (2) - RESTful API design, refactoring patterns, SOLID principles
- **DevOps & Infrastructure** (3) - Docker/Dip setup, APM monitoring, log aggregation
- **Background Jobs** (1) - Sidekiq/Solid Queue patterns, job design, error handling
- **Frontend & UI** (1) - Hotwire (Turbo + Stimulus) integration
- **Documentation** (1) - Automated API docs with Swagger/OpenAPI
- **Modular Architecture** (1) - Packwerk for enforcing package boundaries
- **Language Expertise** (2) - Ruby idioms, Rails conventions, metaprogramming

**5 Pre-configured Bundles**: Backend Dev, Code Auditor, DevOps, API Developer, Performance Engineer

## 🎯 Skills Catalog (18 Total)

### Code Quality & Auditing (3 skills)

- **[rails-audit](skills/rails-audit/SKILL.md)** - Comprehensive code audits with SimpleCov test coverage, RubyCritic complexity metrics, security scanning (SQL injection, XSS, mass assignment), Ruby idioms analysis, PORO refactoring recommendations, and N+1 query detection. Generates detailed `RAILS_AUDIT_REPORT.md` with severity-ranked findings.

- **[rails-code-reviewer](skills/rails-code-reviewer/SKILL.md)** - Automated code review focusing on SOLID principles, concurrency safety (race conditions, thread safety), performance patterns, and Rails best practices. Provides actionable feedback for architectural improvements.

- **[rails-dead-code-finder](skills/rails-dead-code-finder/SKILL.md)** - Detect unused services, methods, orphaned files, dead imports, and commented code blocks. Analyzes usage across models, controllers, jobs, and helpers with safe removal recommendations.

### Testing (1 skill)

- **[rails-test-helper](skills/rails-test-helper/SKILL.md)** - RSpec and testing best practices including FactoryBot patterns, test doubles/stubs, model/request/integration specs, shared examples, Four Phase Test structure, and avoiding common testing antipatterns.

### Database & Performance (2 skills)

- **[rails-db-optimizer](skills/rails-db-optimizer/SKILL.md)** - Database optimization with missing index detection, query performance analysis (EXPLAIN), migration best practices, composite indexes, counter caches, eager loading patterns, and pagination strategies.

- **[rails-performance-optimizer](skills/rails-performance-optimizer/SKILL.md)** - Application performance optimization including fragment caching, Russian Doll caching, query optimization, N+1 prevention, background job patterns, and Rails-specific performance tuning.

### Security (1 skill)

- **[rails-security-audit](skills/rails-security-audit/SKILL.md)** - Security vulnerability scanning for SQL injection, XSS, CSRF, mass assignment, authentication/authorization issues, and OWASP Top 10 compliance. Includes secure coding patterns and remediation guidance.

### API & Architecture (2 skills)

- **[rails-api-designer](skills/rails-api-designer/SKILL.md)** - RESTful API design patterns, JSON API implementation, API versioning strategies (URL, header, content negotiation), pagination, filtering, error handling, and authentication patterns.

- **[rails-refactoring-guide](skills/rails-refactoring-guide/SKILL.md)** - Code refactoring patterns including Extract Method, Extract Class, Replace Conditional with Polymorphism, SOLID principles application, and architectural improvements for maintainable Rails code.

### DevOps & Infrastructure (3 skills)

- **[rails-docker](skills/rails-docker/SKILL.md)** - Docker and Docker Compose setup for Rails including multi-stage builds, development/production configurations, volume management, environment variables, and container orchestration.

- **[rails-dip](skills/rails-dip/SKILL.md)** - Dip (Docker Interaction Process) integration for simplified Docker workflows. Provides `dip.yml` configuration, common commands (provision, rails, rspec, bundle), and team workflow patterns.

- **[rails-monitoring](skills/rails-monitoring/SKILL.md)** - APM setup (New Relic, Skylight, Datadog), structured logging with Lograge, log aggregation (Papertrail, CloudWatch), custom metrics (StatsD, Prometheus), health check endpoints, and alerting configuration.

### Background Jobs (1 skill)

- **[rails-jobs-helper](skills/rails-jobs-helper/SKILL.md)** - Background job patterns with Sidekiq and Solid Queue including job design, retry strategies, error handling, job monitoring, queue prioritization, and performance optimization.

### Frontend & UI (1 skill)

- **[rails-turbo-stimulus](skills/rails-turbo-stimulus/SKILL.md)** - Hotwire integration with Turbo Frames for partial page updates, Turbo Streams for real-time updates, Stimulus controllers for JavaScript behavior, and modern SPA-like experiences without heavy JavaScript frameworks.

### Documentation (1 skill)

- **[rails-docs-generator](skills/rails-docs-generator/SKILL.md)** - Automated API documentation generation with Swagger/OpenAPI, Rswag integration, Postman collection export, and interactive API documentation for Rails APIs.

### Modular Architecture (1 skill)

- **[rails-packwerk](skills/rails-packwerk/SKILL.md)** - Shopify's Packwerk integration for modular Rails architecture. Enforce package boundaries, privacy violations, dependency constraints, and gradual migration to domain-driven design.

### Language Expertise (2 skills)

- **[ruby-help](skills/ruby-help/SKILL.md)** - Idiomatic Ruby code with Ruby 3.x features (pattern matching, endless methods), metaprogramming patterns, gem development, performance profiling with benchmark-ips, and RSpec/Minitest testing patterns.

- **[rails-help](skills/rails-help/SKILL.md)** - Rails conventions and MVC best practices including ActiveRecord patterns, eager loading, fragment caching, service objects, Hotwire integration, strong parameters, RESTful routing, and background jobs with Sidekiq/ActiveJob.

## 🎭 Role-Based Bundles

Pre-configured skill sets for common Rails development roles:

### Rails Backend Developer
```bash
# Install backend development essentials
cp -r skills/rails-help ~/.claude/skills/
cp -r skills/ruby-help ~/.claude/skills/
cp -r skills/rails-audit ~/.claude/skills/
cp -r skills/rails-test-helper ~/.claude/skills/
cp -r skills/rails-db-optimizer ~/.claude/skills/
```
**Skills:** `rails-help`, `ruby-help`, `rails-audit`, `rails-test-helper`, `rails-db-optimizer`

### Rails Code Auditor
```bash
# Install code quality and audit skills
cp -r skills/rails-audit ~/.claude/skills/
cp -r skills/rails-code-reviewer ~/.claude/skills/
cp -r skills/rails-dead-code-finder ~/.claude/skills/
cp -r skills/rails-security-audit ~/.claude/skills/
cp -r skills/ruby-help ~/.claude/skills/
```
**Skills:** `rails-audit`, `rails-code-reviewer`, `rails-dead-code-finder`, `rails-security-audit`, `ruby-help`

### Rails DevOps Engineer
```bash
# Install DevOps and infrastructure skills
cp -r skills/rails-docker ~/.claude/skills/
cp -r skills/rails-dip ~/.claude/skills/
cp -r skills/rails-monitoring ~/.claude/skills/
cp -r skills/rails-jobs-helper ~/.claude/skills/
```
**Skills:** `rails-docker`, `rails-dip`, `rails-monitoring`, `rails-jobs-helper`

### Rails API Developer
```bash
# Install API development skills
cp -r skills/rails-api-designer ~/.claude/skills/
cp -r skills/rails-help ~/.claude/skills/
cp -r skills/rails-security-audit ~/.claude/skills/
cp -r skills/rails-docs-generator ~/.claude/skills/
```
**Skills:** `rails-api-designer`, `rails-help`, `rails-security-audit`, `rails-docs-generator`

### Rails Performance Engineer
```bash
# Install performance optimization skills
cp -r skills/rails-performance-optimizer ~/.claude/skills/
cp -r skills/rails-db-optimizer ~/.claude/skills/
cp -r skills/rails-monitoring ~/.claude/skills/
```
**Skills:** `rails-performance-optimizer`, `rails-db-optimizer`, `rails-monitoring`

## 🔄 Common Workflows

Step-by-step playbooks for common Rails tasks:

- **[New Rails Project Setup](workflows/new-project-setup.md)** - Initialize a production-ready Rails app
- **[Code Quality Audit](workflows/code-audit.md)** - Run comprehensive code review

## 📚 Documentation

- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute new skills
- **[Testing Guide](TESTING.md)** - How to test skills locally
- **[Publishing Guide](PUBLISHING.md)** - How to publish your own skills
- **[Skills Catalog](CATALOG.md)** - Complete reference of all skills
- **[Next Steps](NEXT_STEPS.md)** - Post-publishing guide

## 🌟 Featured Skills

### rails-audit

Performs comprehensive Ruby on Rails application audits combining Ruby best practices, Rails conventions, testing, security, code design, and performance analysis.

**Key Features:**
- Automated test coverage analysis with SimpleCov
- Code complexity metrics with RubyCritic
- Security vulnerability scanning (SQL injection, XSS, mass assignment)
- Ruby idioms and metaprogramming patterns analysis
- Rails conventions compliance checking
- Fat model/controller detection
- Service Object → PORO refactoring recommendations
- N+1 query detection
- Database optimization opportunities

**Usage:**
```
/rails-audit
```

Generates a detailed `RAILS_AUDIT_REPORT.md` with findings categorized by severity (Critical, High, Medium, Low).

### rails-dead-code-finder

Detects unused code that can be safely removed including unreferenced services, methods with zero usages, orphaned files, and commented code blocks.

**Key Features:**
- Unused service and method detection
- Orphaned file discovery
- Dead background job identification
- Spec-only code flagging
- Safe removal process recommendations

**Usage:**
```
/rails-dead-code-finder
```

Generates `DEAD_CODE_AUDIT.md` with usage counts and removal recommendations.

### rails-db-optimizer

Optimize database performance with index recommendations, query analysis, and migration best practices.

**Key Features:**
- Missing index detection on foreign keys
- N+1 query prevention with eager loading
- Query performance analysis with EXPLAIN
- Composite index recommendations
- Counter cache setup
- Migration safety checks

**Usage:**
```
/rails-db-optimizer
```

### rails-monitoring

Set up comprehensive monitoring for Rails applications in production.

**Key Features:**
- APM setup (New Relic, Skylight, Datadog, Scout APM)
- Structured logging with Lograge
- Log aggregation (Papertrail, CloudWatch, Splunk)
- Custom metrics with StatsD and Prometheus
- Health check endpoints
- Uptime monitoring configuration
- Performance dashboards with Grafana

**Usage:**
```
/rails-monitoring
```

### ruby-help

Get expert guidance on Ruby development including idiomatic code patterns, metaprogramming, gem development, and performance optimization.

**Usage:**
```
/ruby-help
```

### rails-help

Get expert guidance on Rails framework including MVC architecture, ActiveRecord patterns, Hotwire integration, security, and testing.

**Usage:**
```
/rails-help
```

## 📊 Full Catalog

Browse the complete skill catalog:
- [CATALOG.md](CATALOG.md) - All skills with descriptions
- [skills_index.json](data/skills_index.json) - Machine-readable registry

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for:
- How to add new skills
- Skill quality standards
- Testing requirements
- Documentation guidelines

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Built for [Claude Code](https://claude.ai/code) and Cursor users
- Curated for the Rails community

## 📬 Support

- 🐛 [Report Issues](https://github.com/fadynaffa3/RailsOnClaude/issues)
- 💡 [Request Features](https://github.com/fadynaffa3/RailsOnClaude/issues/new)
- 📖 [View Documentation](https://github.com/fadynaffa3/RailsOnClaude#readme)

---

**Made with ❤️ for the Rails community**
