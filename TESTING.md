# Testing RailsOnClaude

Guide for testing skills locally before publishing.

## Prerequisites

- Node.js 16+ with npm/npx
- Claude Code or Cursor installed
- Ruby 3.4+ (for testing Rails skills)
- Rails 8+ (for testing Rails-specific skills)

## Local Testing Methods

### Method 1: NPX Skills CLI (Recommended)

Test individual skills using the npx skills CLI:

```bash
# Navigate to a skill directory
cd skills/rails-audit

# Install to Claude Code
npx skills add .

# Follow prompts to select target (Claude Code, Cursor, etc.)
```

### Method 2: Direct Copy

Copy skills directly to your AI assistant's skills directory:

```bash
# For Claude Code (global)
cp -r skills/rails-audit ~/.claude/skills/

# For Claude Code (project-specific)
cp -r skills/rails-audit /path/to/your/project/.agents/skills/

# For Cursor
cp -r skills/rails-help ~/.cursor/skills/
```

### Method 3: Symlink (Development)

Create symlinks for faster iteration:

```bash
# Link for development
ln -s ~/work/RailsOnClaude/skills/rails-audit ~/.claude/skills/rails-audit

# Changes are immediately reflected without re-copying
```

## Testing Each Skill

### rails-audit

**Setup:**
```bash
# Create a test Rails app
rails new test-app --api --database=mysql
cd test-app

# Add some test code to audit
rails generate model User email:string name:string
rails db:migrate
```

**Test:**
```
# In Claude Code
/rails-audit

# Expected output:
- RAILS_AUDIT_REPORT.md generated
- Findings categorized by severity
- SimpleCov and RubyCritic metrics (if tests exist)
```

**Verify:**
- [ ] Report is generated
- [ ] Security vulnerabilities detected
- [ ] Code smells identified
- [ ] Test coverage calculated (if tests exist)
- [ ] Recommendations are actionable

### ruby-help

**Test:**
```
# In Claude Code
/ruby-help

# Ask questions like:
"Show me idiomatic Ruby code for filtering an array"
"How do I use metaprogramming to define dynamic methods?"
"What's the best way to handle exceptions in Ruby?"
```

**Verify:**
- [ ] Responses use Ruby 3.x syntax
- [ ] Code examples are idiomatic
- [ ] Explanations are clear
- [ ] Best practices are followed

### rails-help

**Test:**
```
# In Claude Code
/rails-help

# Ask questions like:
"How do I prevent N+1 queries in this controller?"
"What's the proper way to use strong parameters?"
"Show me RESTful routing best practices"
```

**Verify:**
- [ ] Responses follow Rails conventions
- [ ] MVC architecture is respected
- [ ] Security best practices included
- [ ] Performance optimizations suggested

## Testing Bundles

### rails-backend-dev Bundle

```bash
# Install bundle
bash bundles/rails-backend-dev/install.sh

# Verify all skills are available
# In Claude Code:
/rails-help    # Should work
/ruby-help     # Should work
/rails-audit   # Should work
```

### rails-auditor Bundle

```bash
# Install bundle
cp -r skills/rails-audit ~/.claude/skills/
cp -r skills/ruby-help ~/.claude/skills/

# Test audit workflow
/rails-audit
# Review RAILS_AUDIT_REPORT.md
/ruby-help "How do I refactor this fat model?"
```

## Testing Workflows

### New Rails Project Setup

Follow the workflow in `workflows/new-project-setup.md`:

```bash
# Step-by-step verification
rails new test-project --api
cd test-project

# Test each skill invocation
/ruby-help help me configure RSpec
/rails-audit
# etc.
```

**Verify:**
- [ ] Each step completes successfully
- [ ] Skills provide relevant guidance
- [ ] Final project is production-ready

### Code Audit Workflow

Follow the workflow in `workflows/code-audit.md`:

```bash
# In existing Rails project
/rails-audit

# Verify report quality
cat RAILS_AUDIT_REPORT.md

# Test refactoring guidance
/ruby-help "How do I extract this into a PORO?"
```

## Automated Testing (Coming Soon)

Future: Automated test suite for skills

```bash
# Run all skill tests
npm test

# Test specific skill
npm test -- rails-audit

# Test in CI
npm run test:ci
```

## Integration Testing

Test with real Rails applications:

### Small App (~100 LOC)

```bash
git clone https://github.com/fadynaffa3/small-rails-app
cd small-rails-app
/rails-audit
```

**Verify:**
- [ ] Audit completes in < 1 minute
- [ ] Findings are relevant
- [ ] No false positives

### Medium App (~1000 LOC)

```bash
git clone https://github.com/fadynaffa3/medium-rails-app
cd medium-rails-app
/rails-audit
```

**Verify:**
- [ ] Audit completes in < 5 minutes
- [ ] Performance is acceptable
- [ ] Memory usage is reasonable

### Large App (~10,000+ LOC)

```bash
cd /path/to/large/rails/app
/rails-audit
```

**Verify:**
- [ ] Audit completes (may take 10-20 minutes)
- [ ] No timeout errors
- [ ] Report is comprehensive

## Compatibility Testing

Test across different environments:

### Claude Code

```bash
# Global skills
cp -r skills/* ~/.claude/skills/

# Test each skill
/rails-audit
/ruby-help
/rails-help
```

### Cursor

```bash
# Cursor skills
cp -r skills/* ~/.cursor/skills/

# Test in Cursor
@rails-audit
@ruby-help
@rails-help
```

### Different Ruby/Rails Versions

Test with multiple versions:

```bash
# Ruby 3.1 + Rails 7.0
rbenv local 3.1.0
gem install rails -v 7.0.0
/rails-audit

# Ruby 3.4 + Rails 8.0
rbenv local 3.4.0
gem install rails -v 8.0.0
/rails-audit
```

## Performance Testing

### Benchmark Audit Speed

```bash
# Time the audit
time /rails-audit

# Expected:
# Small app: < 1 minute
# Medium app: 1-5 minutes
# Large app: 5-20 minutes
```

### Memory Usage

```bash
# Monitor memory during audit
/rails-audit &
watch -n 1 'ps aux | grep claude'
```

## Regression Testing

After making changes:

```bash
# Run against known-good Rails app
cd test-fixtures/sample-app
/rails-audit > output-new.txt

# Compare with baseline
diff output-baseline.txt output-new.txt
```

## Edge Cases to Test

- [ ] Empty Rails app (no models/controllers)
- [ ] API-only Rails app
- [ ] Rails app with Hotwire
- [ ] Rails app with GraphQL
- [ ] Monolithic Rails app
- [ ] Rails engines
- [ ] Rails app with concerns
- [ ] Rails app with service objects

## Common Issues

### Skill Not Found

**Symptom:** `/rails-audit` command not recognized

**Fix:**
```bash
# Verify skill is installed
ls ~/.claude/skills/rails-audit

# Reinstall if missing
cp -r skills/rails-audit ~/.claude/skills/
```

### Incorrect Output

**Symptom:** Skill gives wrong recommendations

**Fix:**
- Check SKILL.md instructions
- Verify reference materials are up to date
- Test with simpler example

### Performance Issues

**Symptom:** Skill takes too long

**Fix:**
- Profile the skill execution
- Optimize subagents
- Consider scoping the audit

## Reporting Test Results

When reporting issues, include:

1. **Environment:**
   - OS version
   - Ruby version
   - Rails version
   - Claude Code/Cursor version

2. **Steps to reproduce:**
   - Exact commands run
   - Sample code (if relevant)

3. **Expected behavior:**
   - What should happen

4. **Actual behavior:**
   - What actually happened
   - Error messages
   - Screenshots

5. **Logs:**
   ```bash
   # Enable debug mode
   DEBUG=* /rails-audit
   ```

## Test Checklist

Before submitting a PR:

- [ ] All skills tested individually
- [ ] Bundles tested
- [ ] Workflows tested end-to-end
- [ ] Tested on Claude Code
- [ ] Tested on Cursor (if possible)
- [ ] Tested with multiple Ruby/Rails versions
- [ ] Performance is acceptable
- [ ] No regressions introduced
- [ ] Documentation is accurate

---

Happy testing! 🧪
