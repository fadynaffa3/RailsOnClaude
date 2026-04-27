# Workflow: Comprehensive Code Audit

Run a thorough code audit on a Rails application to identify quality issues, security vulnerabilities, and improvement opportunities.

## Overview

Perform systematic code review covering testing, security, architecture, and performance.

## Prerequisites

- Existing Rails application
- Claude Code with RailsOnClaude installed
- RSpec test suite (recommended)

## Steps

### 1. Prepare Repository

```bash
# Ensure all changes are committed
git status

# Update dependencies
bundle update

# Run tests to establish baseline
bundle exec rspec
```

### 2. Run Comprehensive Audit

**In Claude Code:**
```
/rails-audit
```

**When prompted about metrics:**
- Select "Yes to both (Recommended)" to collect:
  - **SimpleCov**: Actual test coverage percentages
  - **RubyCritic**: Code complexity and smell metrics

The audit will:
1. Temporarily add SimpleCov and RubyCritic gems
2. Run your test suite to capture coverage
3. Analyze code complexity
4. Generate comprehensive report
5. Clean up temporary gems and files

### 3. Review Generated Report

Open `RAILS_AUDIT_REPORT.md` in your editor.

Report sections:
- **Executive Summary**: High-level metrics and priorities
- **Testing Coverage & Quality**: Test gaps and patterns
- **Code Quality Metrics**: Complexity and maintainability scores
- **Security Vulnerabilities**: CRITICAL and HIGH severity issues
- **Models & Database**: ActiveRecord issues, N+1 queries
- **Controllers**: Fat controller detection, business logic leakage
- **Code Design & Architecture**: PORO opportunities, SRP violations
- **Views & Presenters**: Logic in views, helper complexity
- **External Services**: API call patterns, error handling
- **Database & Migrations**: Index optimization, migration quality

### 4. Triage Findings by Severity

**Critical** (Fix immediately):
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization bypasses
- Data loss risks

**High** (Fix before next release):
- Missing tests for critical paths
- N+1 query problems
- Mass assignment vulnerabilities
- Missing database indexes

**Medium** (Address in next sprint):
- Fat models/controllers
- Service Object → PORO refactoring
- Code complexity issues
- Missing validations

**Low** (Track as tech debt):
- Style inconsistencies
- Minor improvements
- Optimization opportunities

### 5. Create Linear Issues

**In Claude Code:**
```
Help me create Linear issues for the Critical and High severity findings from the audit report.
```

### 6. Fix Critical Issues First

Start with security vulnerabilities:

**In Claude Code:**
```
/rails-help

Help me fix the SQL injection vulnerability in [file:line]
```

### 7. Address Test Coverage Gaps

Focus on untested critical paths:

**In Claude Code:**
```
/ruby-help

Help me write RSpec tests for [model/controller] to improve coverage
```

### 8. Refactor Code Smells

**In Claude Code:**
```
/ruby-help

Help me refactor this fat model into POROs following best practices
```

### 9. Optimize Database Queries

**In Claude Code:**
```
/rails-help

Help me add eager loading to eliminate N+1 queries in [controller]
```

### 10. Re-run Audit

After fixes:

```
/rails-audit
```

Compare new report with original to verify improvements.

### 11. Update Documentation

Document:
- Architecture decisions made
- Refactoring patterns used
- Security fixes applied
- Test coverage improvements

## Verification Checklist

- [ ] Audit report generated successfully
- [ ] All Critical severity issues addressed
- [ ] High severity issues scheduled for fix
- [ ] Linear issues created for Medium severity items
- [ ] Test coverage improved (target: >80%)
- [ ] RuboCop violations reduced
- [ ] Database indexes added where needed
- [ ] Security vulnerabilities patched
- [ ] Re-audit shows improvements

## Common Findings

### Fat Models
**Issue**: Models with >200 lines or >15 public methods

**Fix**: Extract to POROs with composition
```ruby
# Instead of User model with 50 methods
# Extract to:
Users::ProfileBuilder.new(user)
Users::NotificationPreferences.new(user)
```

### Fat Controllers
**Issue**: Controller actions >15 lines with business logic

**Fix**: Extract to form objects or actions
```ruby
# Instead of
def create
  @user = User.new(user_params)
  @user.generate_api_key
  @user.send_welcome_email
  # ...
end

# Use
def create
  result = Users::Create.call(params: user_params)
  # ...
end
```

### N+1 Queries
**Issue**: Missing eager loading causing multiple DB queries

**Fix**: Use includes/joins
```ruby
# Instead of
@posts = Post.all
@posts.each { |p| p.author.name }

# Use
@posts = Post.includes(:author)
```

### Missing Tests
**Issue**: Critical paths with 0% coverage

**Fix**: Write request specs first
```ruby
RSpec.describe "Orders API", type: :request do
  describe "POST /orders" do
    it "creates an order successfully" do
      # ...
    end
  end
end
```

## Skills Used

- `/rails-audit` - Comprehensive audit
- `/ruby-help` - Refactoring guidance
- `/rails-help` - Rails patterns and optimization

## Estimated Time

- Initial audit: 10-15 minutes
- Report review: 30 minutes
- Fix Critical issues: 1-2 hours
- Fix High issues: 2-4 hours
- Address Medium issues: 4-8 hours (over multiple sprints)

## Next Steps

- Schedule regular audits (quarterly)
- Set up pre-commit hooks for RuboCop
- Add audit findings to technical debt backlog
- Configure CI to enforce coverage thresholds
- Share audit report with team for learning

## Pro Tips

1. **Run audits before major releases** to catch issues early
2. **Compare reports over time** to track code quality trends
3. **Focus on high-impact fixes** rather than style issues
4. **Use audit as learning opportunity** for junior developers
5. **Automate what you can** (SimpleCov, RuboCop in CI)
