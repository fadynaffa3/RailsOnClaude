# Skills Catalog

Complete reference of all skills in the RailsOnClaude collection.

## Table of Contents

- [Code Quality & Auditing](#code-quality--auditing)
- [Language & Framework](#language--framework)

---

## Code Quality & Auditing

### rails-audit

**Path:** `skills/rails-audit/`

**Description:** Perform comprehensive code audits of Ruby on Rails applications based on thoughtbot best practices. Analyzes testing practices (RSpec), security vulnerabilities, code design (skinny controllers, domain models, PORO), Rails conventions, database optimization, and Ruby best practices.

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

**Total Skills:** 3

**Last Updated:** 2026-04-27
