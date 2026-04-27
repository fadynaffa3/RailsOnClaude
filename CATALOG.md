# Skills Catalog

Complete reference of all skills in the RailsOnClaude collection.

## Table of Contents

- [Code Quality & Auditing](#code-quality--auditing)
- [Testing](#testing)
- [Database & Performance](#database--performance)
- [Security](#security)
- [API & Architecture](#api--architecture)
- [DevOps & Infrastructure](#devops--infrastructure)
- [Background Jobs](#background-jobs)
- [Frontend & UI](#frontend--ui)
- [Documentation](#documentation)
- [Modular Architecture](#modular-architecture)
- [Upgrades & Maintenance](#upgrades--maintenance)
- [Language & Framework](#language--framework)

---

## Code Quality & Auditing

### rails-audit

**Path:** `skills/rails-audit/`

**Description:** Perform comprehensive code audits of Ruby on Rails applications. Analyzes testing practices (RSpec), security vulnerabilities, code design (skinny controllers, domain models, PORO), Rails conventions, database optimization, and Ruby best practices. Methodology inspired by industry-proven Rails development patterns.

**Category:** Code Quality, Testing, Security

**Risk Level:** Low

**Usage:**
```
/rails-audit              # Full audit
/rails-audit audit models # Targeted audit
```

**Features:**
- Test coverage analysis with SimpleCov integration
- Code complexity metrics with RubyCritic
- Security vulnerability detection (SQL injection, XSS, mass assignment)
- Fat model/controller detection
- Service Object → PORO refactoring recommendations
- N+1 query risk identification
- Law of Demeter violations
- Callback complexity analysis

**Subagents:**
- `simplecov_agent` - Automated test coverage measurement
- `rubycritic_agent` - Code quality and complexity analysis

**References:**
- Code smells detection patterns
- Testing best practices guidelines
- PORO patterns with ActiveModel
- Security checklist (OWASP)
- Rails antipatterns
- Audit report template

**Output:** Generates `RAILS_AUDIT_REPORT.md` with severity-ranked findings

**When to Use:**
- Before production deployments
- After major refactoring
- Code review preparation
- Technical debt assessment
- Security compliance audits

---

### rails-code-reviewer

**Path:** `skills/rails-code-reviewer/`

**Description:** Automated code review focusing on SOLID principles, concurrency safety, performance patterns, and Rails best practices.

**Category:** Code Quality, Code Review

**Risk Level:** Low

**Usage:**
```
/rails-code-reviewer
```

---

### rails-dead-code-finder

**Path:** `skills/rails-dead-code-finder/`

**Description:** Detect and remove unused code including dead methods, orphaned files, and commented code blocks.

**Category:** Code Quality, Maintenance

**Risk Level:** Low

**Usage:**
```
/rails-dead-code-finder
```

---

## Testing

### rails-test-helper

**Path:** `skills/rails-test-helper/`

**Description:** RSpec and testing best practices for Rails applications. Helps write effective tests, set up FactoryBot, configure test doubles, and follow TDD/BDD patterns.

**Category:** Testing

**Risk Level:** Low

**Usage:**
```
/rails-test-helper
```

**Features:**
- RSpec setup and configuration
- FactoryBot patterns
- Model, request, and integration specs
- Test doubles and stubs
- Shared examples and contexts
- Four Phase Test structure

---

## Database & Performance

### rails-db-optimizer

**Path:** `skills/rails-db-optimizer/`

**Description:** Database optimization including migration best practices, index optimization, query performance analysis, and database design patterns.

**Category:** Performance, Database

**Risk Level:** Medium

**Usage:**
```
/rails-db-optimizer
```

**Features:**
- Missing index detection
- Query optimization (N+1, eager loading)
- Migration best practices
- Counter caches
- Database design patterns

---

### rails-performance-optimizer

**Path:** `skills/rails-performance-optimizer/`

**Description:** Application performance optimization including caching strategies, query optimization, and Rails-specific performance patterns.

**Category:** Performance

**Risk Level:** Low

**Usage:**
```
/rails-performance-optimizer
```

---

## Security

### rails-security-audit

**Path:** `skills/rails-security-audit/`

**Description:** Security vulnerability scanning and OWASP compliance checking for Rails applications.

**Category:** Security

**Risk Level:** Low

**Usage:**
```
/rails-security-audit
```

---

## API & Architecture

### rails-api-designer

**Path:** `skills/rails-api-designer/`

**Description:** RESTful API design patterns, JSON API implementation, versioning strategies, and API documentation.

**Category:** API Design

**Risk Level:** Low

**Usage:**
```
/rails-api-designer
```

---

### rails-refactoring-guide

**Path:** `skills/rails-refactoring-guide/`

**Description:** Code refactoring patterns, SOLID principles, and architectural improvements for Rails applications.

**Category:** Refactoring, Architecture

**Risk Level:** Low

**Usage:**
```
/rails-refactoring-guide
```

---

## DevOps & Infrastructure

### rails-docker

**Path:** `skills/rails-docker/`

**Description:** Docker and Docker Compose setup for Rails applications including production-ready configurations.

**Category:** DevOps, Infrastructure

**Risk Level:** Medium

**Usage:**
```
/rails-docker
```

---

### rails-dip

**Path:** `skills/rails-dip/`

**Description:** Dip (Docker Interaction Process) integration for simplified Docker workflows in Rails development.

**Category:** DevOps, Development Tools

**Risk Level:** Low

**Usage:**
```
/rails-dip
```

---

### rails-monitoring

**Path:** `skills/rails-monitoring/`

**Description:** Application monitoring setup including APM tools, log aggregation, error tracking, uptime monitoring, and performance dashboards.

**Category:** Monitoring, Observability

**Risk Level:** Medium

**Usage:**
```
/rails-monitoring
```

**Features:**
- APM setup (New Relic, Skylight, Datadog)
- Structured logging with Lograge
- Log aggregation (Papertrail, CloudWatch)
- Custom metrics (StatsD, Prometheus)
- Health check endpoints
- Alerting configuration

---

## Background Jobs

### rails-jobs-helper

**Path:** `skills/rails-jobs-helper/`

**Description:** Background job patterns with Sidekiq and Solid Queue including job design, error handling, and monitoring.

**Category:** Background Jobs

**Risk Level:** Low

**Usage:**
```
/rails-jobs-helper
```

---

## Frontend & UI

### rails-turbo-stimulus

**Path:** `skills/rails-turbo-stimulus/`

**Description:** Hotwire integration including Turbo Frames, Turbo Streams, and Stimulus controllers for modern Rails frontend.

**Category:** Frontend, Hotwire

**Risk Level:** Low

**Usage:**
```
/rails-turbo-stimulus
```

---

## Documentation

### rails-docs-generator

**Path:** `skills/rails-docs-generator/`

**Description:** Automated documentation generation for Rails APIs including Swagger/OpenAPI and Postman collections.

**Category:** Documentation

**Risk Level:** Low

**Usage:**
```
/rails-docs-generator
```

---

## Modular Architecture

### rails-packwerk

**Path:** `skills/rails-packwerk/`

**Description:** Shopify's Packwerk integration for modular Rails architecture and enforcing package boundaries.

**Category:** Architecture, Modularity

**Risk Level:** Medium

**Usage:**
```
/rails-packwerk
```

---

## Upgrades & Maintenance

### ruby-4-upgrade-prep

**Path:** `skills/ruby-4-upgrade-prep/`

**Description:** Prepare Ruby on Rails applications for Ruby 4.0 upgrade. Analyzes deprecation warnings, identifies breaking changes, detects incompatible patterns, and provides migration path recommendations based on Ruby 3.x deprecations and historical upgrade patterns.

**Category:** Upgrades, Maintenance

**Risk Level:** Low

**Usage:**
```
/ruby-4-upgrade-prep
```

**Features:**
- Deprecation warning analysis with RUBYOPT
- Keyword argument pattern detection
- Gem compatibility checking
- String mutation pattern analysis
- Numbered parameter detection in nested blocks
- ActiveRecord deprecated pattern scanning
- Native extension gem identification
- Performance and memory pattern auditing
- Comprehensive upgrade readiness report generation

**Output:** Generates `RUBY_4_UPGRADE_READINESS.md` with:
- Executive summary with readiness percentage
- Deprecation warnings categorized by severity
- Gem compatibility matrix
- Code pattern analysis
- Rails-specific issues
- Performance considerations (Fiber, Ractor)
- Phased migration path (4 phases)
- Estimated effort and risk assessment

**When to Use:**
- Planning Ruby 4.0 upgrade strategy
- Future-proofing Ruby 3.x codebase
- Identifying deprecation warnings
- Analyzing gem compatibility risks
- Preparing for breaking changes

---

## Language & Framework

### ruby-help

**Path:** `skills/ruby-help/`

**Description:** Expert guidance for writing idiomatic Ruby code with metaprogramming, Rails patterns, and performance optimization. Specializes in Ruby on Rails, gem development, and testing frameworks.

**Category:** Language Expertise, Best Practices

**Risk Level:** Low

**Usage:**
```
/ruby-help
```

**Features:**
- Ruby 3.x modern syntax and features
- Metaprogramming patterns (modules, mixins, DSLs)
- Gem development and versioning
- Performance optimization and profiling
- RSpec and Minitest testing patterns
- Code quality with RuboCop
- Block and enumerable patterns
- Exception handling strategies

**Focus Areas:**
- Clean, maintainable Ruby code
- Ruby expressiveness and idioms
- Performance benchmarking
- Static analysis integration
- Testing best practices

**When to Use:**
- Learning Ruby best practices
- Code review and refactoring
- Gem development
- Performance optimization
- Testing strategy

---

### rails-help

**Path:** `skills/rails-help/`

**Description:** Expert in Ruby and Rails development with conventions and best practices. Covers MVC architecture, ActiveRecord patterns, Hotwire integration, security, and performance.

**Category:** Framework Expertise, Web Development

**Risk Level:** Low

**Usage:**
```
/rails-help
```

**Features:**
- Rails conventions (Convention over Configuration)
- ActiveRecord patterns and optimization
- N+1 query prevention with eager loading
- Fragment and Russian Doll caching
- Service objects for business logic
- Hotwire (Turbo + Stimulus) integration
- Tailwind CSS responsive design
- ViewComponents for reusable UI
- Authentication (Devise) and authorization (Pundit)
- Strong parameters and CSRF protection
- RESTful routing conventions

**Architecture Patterns:**
- Thin controllers, fat models (with limits)
- Concerns for shared functionality
- Background jobs (Sidekiq/ActiveJob)
- Database migrations best practices

**Testing:**
- RSpec/Minitest with TDD practices
- FactoryBot for test data
- Mocking external services
- Shared examples for DRY tests

**When to Use:**
- Building Rails applications
- Following Rails conventions
- Performance optimization
- Security implementation
- Testing strategy

---

## Skill Structure

Each skill follows this directory structure:

```
skills/[skill-name]/
├── SKILL.md              # Main skill definition and metadata
├── README.md             # Usage documentation
├── LICENSE               # License information
├── CODEOWNERS           # Maintainer information
├── agents/              # Subagent definitions (optional)
│   └── *.md
└── references/          # Knowledge base and guidelines (optional)
    └── *.md
```

## Installation Paths

| Tool | Global Path | Project Path |
|------|-------------|--------------|
| Claude Code | `~/.claude/skills/` | `.agents/skills/` |
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` |

## Skill Metadata

Each skill includes frontmatter with:

- `name` - Skill identifier (kebab-case)
- `description` - One-line summary for skill discovery
- `category` - Primary category (optional)
- `risk` - Risk level: low, medium, high (optional)
- `license` - License identifier (optional)
- `source` - Source type: community, official, verified (optional)

---

**Total Skills:** 19

**Last Updated:** 2026-04-27
