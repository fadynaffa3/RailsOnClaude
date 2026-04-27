# RailsOnClaude 🛤️

> A curated collection of AI assistant skills for Ruby on Rails development with Claude Code, Cursor, and other AI coding tools.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Quick Start

### Install via NPX (Recommended)

```bash
# Install all skills
npx skills add fadynaffa3/RailsOnClaude

# Or install individual skills
npx skills add fadynaffa3/RailsOnClaude/skills/rails-audit
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

# Install only Ruby help skill
cp -r skills/ruby-help ~/.claude/skills/

# Install only Rails help skill
cp -r skills/rails-help ~/.claude/skills/
```

### Usage

**In Claude Code session:**
```
/rails-audit                     # Run comprehensive Rails audit
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

## 🎯 Skills Catalog

### Code Quality & Auditing

- **[rails-audit](skills/rails-audit/SKILL.md)** - Comprehensive code audits with test coverage, security, and quality metrics
  - RSpec test coverage analysis with SimpleCov
  - Code complexity metrics with RubyCritic
  - Security vulnerability detection
  - Ruby idioms and best practices analysis
  - Rails conventions compliance
  - PORO patterns and service object refactoring
  - Rails anti-patterns identification

### Language & Framework Expertise

- **[ruby-help](skills/ruby-help/SKILL.md)** - Idiomatic Ruby with metaprogramming and performance optimization
  - Ruby 3.x features and patterns
  - Metaprogramming and DSL design
  - Gem development and versioning
  - RSpec/Minitest testing patterns

- **[rails-help](skills/rails-help/SKILL.md)** - Rails conventions and MVC best practices
  - ActiveRecord patterns and optimization
  - Hotwire (Turbo + Stimulus) integration
  - Strong parameters and security
  - Background jobs with Sidekiq/ActiveJob

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
cp -r skills/ruby-help ~/.claude/skills/
```
Includes: `rails-audit`, `ruby-help` - comprehensive code quality and security analysis

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
