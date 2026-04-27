---
name: ruby-4-upgrade-prep
description: Prepare Ruby on Rails applications for Ruby 4.0 upgrade. Analyzes deprecation warnings, identifies breaking changes, detects incompatible patterns, and provides migration path recommendations based on Ruby 3.x deprecations and historical upgrade patterns.
category: maintenance
tags: [ruby, upgrade, migration, deprecations, future-proofing, ruby-4]
---

# Ruby 4.0 Upgrade Preparation

Prepare your Ruby on Rails application for the future Ruby 4.0 release by identifying deprecations, incompatible patterns, and potential breaking changes.

## Use this skill when

- Planning Ruby 4.0 upgrade strategy
- Future-proofing Ruby 3.x codebase
- Identifying deprecation warnings
- Analyzing gem compatibility risks
- Preparing for breaking changes

## Do not use this skill when

- Upgrading Ruby 2.x to 3.x (use existing Ruby 3 upgrade guides)
- Fixing current Ruby 3.x bugs (use ruby-help)
- General code refactoring (use rails-refactoring-guide)

## Instructions

### Step 1: Identify Current State

**Check Ruby and Rails versions:**
```bash
ruby -v
rails -v
bundle show rails
```

**Check Gemfile.lock for Ruby version:**
```bash
grep "RUBY VERSION" Gemfile.lock
```

### Step 2: Analyze Deprecation Warnings

**Run test suite with deprecation warnings:**
```bash
RUBYOPT="-W:deprecated" bundle exec rspec
RUBYOPT="-W:deprecated" bundle exec rails test
```

**Common Ruby 3.x deprecations likely to be removed in Ruby 4.0:**

1. **Keyword argument separation** (enforced since Ruby 3.0)
   ```ruby
   # ❌ Will break in Ruby 4.0
   def method(options)
     # ...
   end
   method(key: "value")  # Passes hash, not keyword args
   
   # ✅ Ruby 4.0 compatible
   def method(**options)
     # ...
   end
   method(key: "value")
   ```

2. **Numbered parameters with nested blocks**
   ```ruby
   # ⚠️ Deprecated pattern
   array.each { |item| item.map { _1 * 2 } }  # _1 refers to outer block
   
   # ✅ Use explicit parameters
   array.each { |item| item.map { |x| x * 2 } }
   ```

3. **Hash#except without requiring Active Support**
   ```ruby
   # Ruby 3.0+ has built-in Hash#except
   # Remove Active Support monkey patches if only using for #except
   ```

4. **Random::DEFAULT deprecation**
   ```ruby
   # ⚠️ Deprecated
   Random::DEFAULT.rand(10)
   
   # ✅ Use Random class directly
   Random.rand(10)
   ```

5. **Refinements scope changes**
   ```ruby
   # ⚠️ Refinement visibility may change
   # Document all refinement usage for review
   ```

### Step 3: Check Gem Compatibility

**Analyze gem dependencies:**
```bash
bundle outdated
bundle list
```

**Critical gems to check:**
```ruby
# Check these gems for Ruby 4.0 compatibility announcements:
# - rails (ensure latest 7.x or 8.x)
# - puma
# - sidekiq / solid_queue
# - devise
# - pundit / cancancan
# - nokogiri
# - pg / mysql2
# - redis
# - elasticsearch
```

**Check for deprecated gem patterns:**
```bash
# Search for gems with native extensions
bundle show --paths | xargs -I {} find {} -name "*.c" -o -name "*.so"

# These may need updates for Ruby 4.0 compatibility
```

### Step 4: Pattern Analysis

**Search for deprecated patterns in codebase:**

**1. Keyword argument issues:**
```bash
# Find methods with ambiguous keyword arguments
grep -r "def.*(\w\+)" app/ lib/ | grep -v "**"
```

**2. Numbered parameters in nested blocks:**
```bash
# Find numbered parameters (_1, _2, etc.)
grep -r "_[0-9]" app/ lib/ --include="*.rb"
```

**3. Monkey patches that may conflict:**
```bash
# Find refinements and monkey patches
grep -r "class <<" app/ lib/
grep -r "refine" app/ lib/
grep -r "\.include" config/initializers/
```

**4. String literals frozen by default:**
```ruby
# Ruby 3.x already has frozen string literals by default
# Check for code that mutates strings in-place

# ❌ May break
str = "hello"
str << " world"  # Mutates string

# ✅ Ruby 4.0 compatible
str = +"hello"  # Unfreeze explicitly
str << " world"

# Or use string concatenation
str = "hello" + " world"
```

**5. Autocorrect with RuboCop:**
```bash
# Use RuboCop to detect deprecated patterns
bundle exec rubocop --only Style/FrozenStringLiteralComment
bundle exec rubocop --only Style/HashSyntax
bundle exec rubocop --only Lint/DeprecatedClassMethods
```

### Step 5: ActiveRecord and Rails Patterns

**Check for deprecated ActiveRecord patterns:**

1. **Using `update_attribute` (bypasses validations):**
   ```bash
   grep -r "update_attribute" app/
   ```
   
   Replace with `update_column` or `update` (with validations)

2. **Dynamic finders (deprecated in Rails):**
   ```bash
   grep -r "find_by_\|find_all_by_\|find_or_create_by_\|find_or_initialize_by_" app/
   ```
   
   Use `find_by`, `where`, `find_or_create_by`, `find_or_initialize_by`

3. **`before_filter` (use `before_action`):**
   ```bash
   grep -r "before_filter\|after_filter\|around_filter" app/
   ```

### Step 6: Performance and Memory Patterns

**Patterns likely to change in Ruby 4.0:**

1. **Fiber scheduling (Async I/O):**
   - Ruby 3.0+ has Fiber scheduler
   - Ruby 4.0 may make Fiber-based concurrency default
   - Audit code that assumes single-threaded execution

2. **GC tuning variables:**
   ```bash
   # Check for GC tuning in environment files
   grep -r "RUBY_GC" config/
   ```
   
   GC tuning parameters may change in Ruby 4.0

3. **Ractor usage (parallel execution):**
   - Ractors are experimental in Ruby 3.x
   - May become default in Ruby 4.0
   - Audit shared state and global variables

### Step 7: Generate Upgrade Readiness Report

Create `RUBY_4_UPGRADE_READINESS.md`:

```markdown
# Ruby 4.0 Upgrade Readiness Report

**Generated:** {{DATE}}
**Current Ruby Version:** {{RUBY_VERSION}}
**Current Rails Version:** {{RAILS_VERSION}}
**Target:** Ruby 4.0 (future release)

---

## Executive Summary

| Category | Status | Issues Found | Risk Level |
|----------|--------|--------------|------------|
| Keyword Arguments | {{STATUS}} | {{COUNT}} | {{RISK}} |
| Deprecated Methods | {{STATUS}} | {{COUNT}} | {{RISK}} |
| Gem Compatibility | {{STATUS}} | {{COUNT}} | {{RISK}} |
| String Mutations | {{STATUS}} | {{COUNT}} | {{RISK}} |
| Pattern Matching | {{STATUS}} | {{COUNT}} | {{RISK}} |

**Overall Readiness:** {{PERCENTAGE}}%

---

## 1. Deprecation Warnings

### Critical (Must Fix Before Ruby 4.0)

**Keyword Argument Issues:**
- File: `app/services/foo.rb:42`
  - Issue: Method definition uses positional hash instead of keyword arguments
  - Fix: Change `def method(options)` to `def method(**options)`
  - Severity: High

### High Priority

**Numbered Parameters in Nested Blocks:**
- File: `app/models/user.rb:87`
  - Issue: Uses `_1` in nested block context
  - Fix: Use explicit block parameters
  - Severity: Medium

### Medium Priority

**String Literal Mutations:**
- File: `lib/parser.rb:23`
  - Issue: Mutates string literal with `<<` operator
  - Fix: Use `+""` prefix to unfreeze or string concatenation
  - Severity: Low

---

## 2. Gem Compatibility Analysis

### Gems Requiring Updates

| Gem | Current Version | Ruby 4.0 Status | Action Required |
|-----|----------------|-----------------|-----------------|
| nokogiri | 1.13.0 | ⚠️ Unknown | Monitor for updates |
| devise | 4.8.0 | ✅ Likely compatible | Test in Ruby 3.4+ |
| sidekiq | 7.0.0 | ✅ Compatible | No action |

### Gems with Native Extensions

- `pg` (1.5.4) - Monitor PostgreSQL adapter compatibility
- `mysql2` (0.5.5) - Monitor MySQL adapter compatibility
- `bootsnap` (1.16.0) - May need recompilation

---

## 3. Code Pattern Analysis

### Patterns Needing Attention

**1. Method Signatures (42 instances)**
- 12 methods with positional hash parameters
- 8 methods with mixed positional/keyword args
- 22 methods missing explicit keyword splat (`**`)

**2. Block Patterns (15 instances)**
- 5 uses of numbered parameters in nested contexts
- 10 uses of `_1` where explicit params are clearer

**3. String Handling (8 instances)**
- 8 in-place string mutations without explicit unfreeze

---

## 4. Rails-Specific Issues

### Deprecated Rails Patterns

**Controllers:**
- 3 uses of `before_filter` (replace with `before_action`)
- 2 uses of `update_attribute` (replace with `update` or `update_column`)

**Models:**
- 1 dynamic finder: `find_by_email` (replace with `find_by(email:)`)
- 5 callback chains over 3 levels (consider extraction)

**Views:**
- No deprecated patterns found ✅

---

## 5. Performance Considerations

### Fiber Scheduler Compatibility
- No blocking I/O found in critical paths ✅
- 2 synchronous HTTP calls in background jobs (consider async)

### Ractor Compatibility
- 8 uses of global variables (not Ractor-safe)
- 12 uses of class variables (not Ractor-safe)

---

## 6. Recommended Migration Path

### Phase 1: Immediate Actions (Pre-Ruby 4.0)

1. **Fix all deprecation warnings in Ruby 3.x**
   ```bash
   RUBYOPT="-W:deprecated" bundle exec rspec
   ```

2. **Update keyword argument patterns**
   - Run: `rubocop -A --only Style/ArgumentsForwarding`
   - Manually review 12 method signatures

3. **Update gems to latest versions**
   ```bash
   bundle update
   ```

### Phase 2: Preparation (6 months before Ruby 4.0 release)

1. **Audit gem compatibility**
   - Check gem changelogs for Ruby 4.0 mentions
   - Test with Ruby 4.0 preview releases

2. **Refactor numbered parameters**
   - Replace `_1` with explicit params in nested contexts

3. **Add frozen string literal comments**
   ```ruby
   # frozen_string_literal: true
   ```

### Phase 3: Testing (Ruby 4.0 release candidate)

1. **Install Ruby 4.0 RC in staging**
   ```bash
   rbenv install 4.0.0-rc1
   ```

2. **Run full test suite**
   ```bash
   bundle exec rspec
   bundle exec rails test:system
   ```

3. **Performance benchmarking**
   - Compare Ruby 3.x vs 4.0 performance
   - Monitor memory usage
   - Check GC statistics

### Phase 4: Production Migration

1. **Canary deployment**
   - Deploy to 10% of servers
   - Monitor for 48 hours

2. **Gradual rollout**
   - Increase to 50% after successful canary
   - Monitor error rates and performance

3. **Full deployment**
   - Deploy to all servers
   - Keep Ruby 3.x rollback plan ready

---

## 7. Estimated Effort

| Task | Estimated Hours | Priority |
|------|----------------|----------|
| Fix keyword arguments | 8-12 | High |
| Update gem dependencies | 4-6 | High |
| Refactor string mutations | 2-4 | Medium |
| Update Rails patterns | 4-6 | Medium |
| Testing and QA | 16-24 | High |
| **Total** | **34-52 hours** | - |

---

## 8. Risk Assessment

**High Risk Areas:**
- Native extension gems (pg, mysql2, nokogiri)
- Custom C extensions
- Heavy metaprogramming code

**Medium Risk Areas:**
- Keyword argument patterns
- String mutation patterns
- Numbered parameters

**Low Risk Areas:**
- Standard Rails patterns
- Well-maintained gems
- Modern Ruby 3.x code

---

## 9. Resources

- [Ruby 4.0 Changelog](https://github.com/ruby/ruby/blob/master/NEWS.md) (when available)
- [Rails Upgrade Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [RuboCop Ruby 4.0 Cops](https://docs.rubocop.org/)

---

## 10. Next Steps

1. ✅ Review this report with team
2. ⬜ Create Jira/Linear tickets for high-priority fixes
3. ⬜ Schedule gem audit sprint
4. ⬜ Set up Ruby 4.0 preview environment
5. ⬜ Plan migration timeline

**Recommended Start Date:** {{START_DATE}}
**Target Completion:** {{END_DATE}}
```

### Step 8: Continuous Monitoring

**Set up deprecation tracking:**

```ruby
# config/initializers/deprecation_tracker.rb
if Rails.env.development? || Rails.env.test?
  ActiveSupport::Deprecation.behavior = lambda do |message, callstack, deprecation_horizon, gem_name|
    # Log to file for analysis
    File.open(Rails.root.join("log", "deprecations.log"), "a") do |f|
      f.puts "[#{Time.current}] #{message}"
      f.puts callstack.first(5).join("\n")
      f.puts "---"
    end
    
    # Also print to console
    warn message
  end
end
```

**Run weekly deprecation checks:**
```bash
# Add to CI pipeline
RUBYOPT="-W:deprecated" bundle exec rspec > deprecations_report.txt 2>&1
```

## Best Practices

### Future-Proofing Strategies

1. **Always use keyword arguments for options hashes:**
   ```ruby
   # ✅ Future-proof
   def process(item, debug: false, verbose: false)
     # ...
   end
   
   # ❌ Avoid
   def process(item, options = {})
     # ...
   end
   ```

2. **Avoid numbered parameters in complex contexts:**
   ```ruby
   # ✅ Clear and maintainable
   users.map { |user| user.posts.map { |post| post.title } }
   
   # ❌ Confusing with nested blocks
   users.map { _1.posts.map { _1.title } }  # Which _1?
   ```

3. **Use frozen string literal comment:**
   ```ruby
   # frozen_string_literal: true
   
   # At top of every file
   ```

4. **Prefer modern Ruby syntax:**
   ```ruby
   # ✅ Modern Ruby 3.x syntax (likely Ruby 4.0 compatible)
   def calculate(amount:, rate:) = amount * rate
   
   case user
   in { role: "admin", active: true }
     grant_access
   in { role: "user" }
     limited_access
   end
   ```

5. **Keep gems up to date:**
   ```bash
   # Run monthly
   bundle update --conservative
   ```

### Testing Strategy

1. **Add Ruby 4.0 to CI matrix (when available):**
   ```yaml
   # .github/workflows/test.yml
   strategy:
     matrix:
       ruby: ['3.3', '3.4', '4.0-preview']
       rails: ['7.1', '7.2', '8.0']
   ```

2. **Run deprecation checks in CI:**
   ```yaml
   - name: Check for deprecations
     run: |
       RUBYOPT="-W:deprecated" bundle exec rspec 2>&1 | tee deprecations.log
       if grep -q "deprecated" deprecations.log; then
         echo "::warning::Deprecation warnings found"
       fi
   ```

## Common Mistakes to Avoid

- ❌ Ignoring deprecation warnings in Ruby 3.x
- ❌ Using outdated gems that may not support Ruby 4.0
- ❌ Mutating frozen string literals without unfreezing
- ❌ Mixing positional and keyword arguments
- ❌ Using numbered parameters in nested blocks
- ❌ Assuming Ruby 4.0 will have same performance characteristics
- ❌ Not testing with Ruby 4.0 preview releases
- ❌ Upgrading gems and Ruby version simultaneously
- ❌ Skipping load testing after upgrade

## Historical Context

**Lessons from Ruby 2.7 → 3.0 upgrade:**

- Keyword argument separation was the biggest breaking change
- Gems with native extensions had compatibility issues
- Performance characteristics changed (GC improvements)
- Some gems took 6-12 months to become Ruby 3.0 compatible

**Expected Ruby 4.0 changes (speculation based on Ruby evolution):**

- Stricter frozen string literals (possibly enabled by default)
- Fiber scheduler as default for I/O operations
- Ractor improvements and potential default parallel execution
- Continued focus on performance (faster JIT, improved GC)
- Removal of long-deprecated features from Ruby 2.x era
- Type annotation support (possibly RBS integration)

## Verification Checklist

Before marking Ruby 4.0 upgrade readiness complete:

- [ ] All deprecation warnings resolved
- [ ] Test suite passes with `RUBYOPT="-W:deprecated"`
- [ ] All gems updated to latest versions
- [ ] Native extension gems recompiled successfully
- [ ] Keyword arguments audited and fixed
- [ ] String mutation patterns refactored
- [ ] Performance benchmarks show acceptable results
- [ ] Load testing completed in staging environment
- [ ] Rollback plan documented and tested
- [ ] Team trained on Ruby 4.0 changes
