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
/rails-audit                     # Run comprehensive Rails audit
/rails-dead-code-finder          # Find and remove unused code
/ruby-help                       # Get Ruby best practices help
/rails-help                      # Get Rails framework guidance
```

## 📦 What's Inside

This collection includes battle-tested skills for:

- **Code Quality**: Comprehensive Rails audits, RuboCop integration, code smell detection
- **Testing**: RSpec/Minitest patterns, coverage analysis, test optimization
- **Development**: Rails conventions, Ruby idioms, metaprogramming patterns
- **Security**: Vulnerability scanning, best practices, OWASP compliance
- **Performance**: N+1 detection, database optimization, caching strategies

## 🎯 Skills Catalog (18 Total)

### Code Quality & Auditing (3 skills)

- **[rails-audit](skills/rails-audit/SKILL.md)** - Comprehensive code audits with test coverage, security, and quality metrics
- **[rails-code-reviewer](skills/rails-code-reviewer/SKILL.md)** - Automated code review for SOLID principles, concurrency, and performance
- **[rails-dead-code-finder](skills/rails-dead-code-finder/SKILL.md)** - Detect and remove unused code

### Testing (1 skill)

- **[rails-test-helper](skills/rails-test-helper/SKILL.md)** - RSpec and testing best practices for Rails applications

### Database & Performance (2 skills)

- **[rails-db-optimizer](skills/rails-db-optimizer/SKILL.md)** - Database optimization, migrations, and index management
- **[rails-performance-optimizer](skills/rails-performance-optimizer/SKILL.md)** - Application performance optimization and caching strategies

### Security (1 skill)

- **[rails-security-audit](skills/rails-security-audit/SKILL.md)** - Security vulnerability scanning and OWASP compliance

### API & Architecture (2 skills)

- **[rails-api-designer](skills/rails-api-designer/SKILL.md)** - RESTful API design and JSON API implementation
- **[rails-refactoring-guide](skills/rails-refactoring-guide/SKILL.md)** - Code refactoring patterns and SOLID principles

### DevOps & Infrastructure (3 skills)

- **[rails-docker](skills/rails-docker/SKILL.md)** - Docker and Docker Compose setup for Rails
- **[rails-dip](skills/rails-dip/SKILL.md)** - Dip (Docker Interaction Process) integration
- **[rails-monitoring](skills/rails-monitoring/SKILL.md)** - APM, logging, and application monitoring

### Background Jobs (1 skill)

- **[rails-jobs-helper](skills/rails-jobs-helper/SKILL.md)** - Background job patterns with Sidekiq and Solid Queue

### Frontend & UI (1 skill)

- **[rails-turbo-stimulus](skills/rails-turbo-stimulus/SKILL.md)** - Hotwire (Turbo Frames, Turbo Streams, Stimulus) integration

### Documentation (1 skill)

- **[rails-docs-generator](skills/rails-docs-generator/SKILL.md)** - Automated documentation generation for Rails APIs

### Modular Architecture (1 skill)

- **[rails-packwerk](skills/rails-packwerk/SKILL.md)** - Shopify's Packwerk for modular Rails architecture

### Language Expertise (2 skills)

- **[ruby-help](skills/ruby-help/SKILL.md)** - Idiomatic Ruby with metaprogramming and performance optimization
- **[rails-help](skills/rails-help/SKILL.md)** - Rails conventions and MVC best practices

## 🎭 Role-Based Bundles

Pre-configured skill sets for common Rails development roles:

### Rails Backend Developer
```bash
# Install all three skills
cp -r skills/rails-help ~/.claude/skills/
cp -r skills/ruby-help ~/.claude/skills/
cp -r skills/rails-audit ~/.claude/skills/
```
Includes: `rails-help`, `ruby-help`, `rails-audit`

### Rails Code Auditor
```bash
# Install audit skills
cp -r skills/rails-audit ~/.claude/skills/
cp -r skills/rails-dead-code-finder ~/.claude/skills/
cp -r skills/ruby-help ~/.claude/skills/
```
Includes: `rails-audit`, `rails-dead-code-finder`, `ruby-help` - comprehensive code quality, dead code detection, and security analysis

See [bundles/rails-auditor](bundles/rails-auditor/README.md) for more details.

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
