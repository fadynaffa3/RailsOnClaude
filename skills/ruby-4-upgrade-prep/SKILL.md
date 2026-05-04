---
name: ruby-4-upgrade-prep
description: Prepare Ruby on Rails applications for Ruby 4.0 upgrade. Analyzes actual breaking changes from Ruby 4.0.0 release including process creation removal, Ractor API changes, Set/Pathname core promotion, and *nil splat behavior changes.
category: maintenance
tags: [ruby, upgrade, migration, ruby-4, breaking-changes, compatibility]
---

# Ruby 4.0 Upgrade Preparation

Analyze your Ruby on Rails application for Ruby 4.0 compatibility using **actual breaking changes** from the Ruby 4.0.0 release.

**Ruby 4.0.3 is now released** - Latest stable: 4.0.3

## Use this skill when

- Planning Ruby 4.0 upgrade from Ruby 3.x
- Analyzing compatibility before upgrade
- Identifying breaking changes in codebase
- Checking gem compatibility with Ruby 4.0
- Preparing migration strategy

## Do not use this skill when

- Upgrading Ruby 2.x to 3.x (use Ruby 3 upgrade guides)
- Fixing current Ruby bugs (use ruby-help)
- General code refactoring (use rails-refactoring-guide)

## Instructions

### Step 1: Identify Current State

**Check Ruby and Rails versions:**
```bash
ruby -v
rails -v
bundle show rails
```

**Check Gemfile.lock:**
```bash
grep -A 1 "RUBY VERSION" Gemfile.lock
```

### Step 2: Analyze Actual Ruby 4.0 Breaking Changes

Based on official Ruby 4.0.0 changelog, check for these **actual** breaking changes:

#### Breaking Change 1: `*nil` No Longer Calls `nil.to_a`

**Search for `*nil` splat usage:**
```bash
grep -r "\*nil" app/ lib/ --include="*.rb"
```

**What changed:**
```ruby
# Ruby 3.x behavior
def foo(*args); end
foo(*nil)  # Called nil.to_a, passed empty array

# Ruby 4.0 behavior
foo(*nil)  # Does NOT call nil.to_a, passes nothing
```

**Fix:** If you need explicit empty array, use `*[]` or `*Array(nil)`.

#### Breaking Change 2: Process Creation with `|` Removed

**Removed features:**
- `IO.read("|command")`
- `IO.write("|command", data)`
- `IO.readlines("|command")`
- `IO.foreach("|command")`
- `IO.binread("|command")`
- `IO.binwrite("|command", data)`
- `Kernel#open("|command")`

**Search for removed patterns:**
```bash
# Find pipe-based process creation
grep -r 'open\s*(\s*['"'"'"]|' app/ lib/ --include="*.rb"
grep -r 'IO\.\(read\|write\|readlines\|foreach\|binread\|binwrite\)\s*(\s*['"'"'"]|' app/ lib/ --include="*.rb"
```

**Migration:**
```ruby
# ❌ Removed in Ruby 4.0
IO.read("|ls -la")
open("|git log") { |f| f.read }

# ✅ Use Open3 or backticks explicitly
require 'open3'
stdout, stderr, status = Open3.capture3("ls -la")

# Or use backticks
`ls -la`

# Or Process.spawn
Process.spawn("ls", "-la")
```

#### Breaking Change 3: Ractor API Changes

**Removed Ractor methods:**
- `Ractor.yield` → Use `Ractor::Port` instead
- `Ractor#take` → Use `Ractor::Port` instead
- `Ractor#close_incoming` → Removed
- `Ractor#close_outgoing` → Removed

**New Ractor API:**
- `Ractor::Port` class added
- `Ractor#join` and `Ractor#value` added
- `Ractor#default_port` added

**Search for Ractor usage:**
```bash
grep -r "Ractor\." app/ lib/ --include="*.rb"
grep -r "\.yield\|\.take\|close_incoming\|close_outgoing" app/ lib/ --include="*.rb" | grep -i ractor
```

**Migration:**
```ruby
# ❌ Old Ractor API (Ruby 3.x)
r = Ractor.new do
  Ractor.yield(42)
end
value = r.take

# ✅ New Ractor API (Ruby 4.0+)
port = Ractor::Port.new
r = Ractor.new port do |port|
  port << 42
end
value = port.receive
```

#### Breaking Change 4: Set is Now a Core Class

**Impact:** `Set` no longer requires `require 'set'`

**Search for requires:**
```bash
grep -rn "require ['\"]set['\"]" app/ lib/ --include="*.rb"
```

**⚠️ IMPORTANT - Timing:**
```ruby
# Ruby 3.x (BEFORE upgrade) - MUST KEEP
require "set"           # ✅ REQUIRED - removing breaks code
Set.new([1, 2, 3])

# Ruby 4.0+ (AFTER upgrade) - Optional cleanup
require "set"           # ✅ Still works (harmless, redundant)
Set.new([1, 2, 3])

# Or remove require (optional):
Set.new([1, 2, 3])      # ✅ Set is core class now
```

**Action:**
- **DO NOT remove `require "set"` in Ruby 3.x** - it will break the code
- **AFTER upgrading to Ruby 4.0:** Optionally remove for cleanup (purely cosmetic)
- Keeping `require "set"` in Ruby 4.0 is perfectly fine

**Deprecation:** `Set#to_set` and `Enumerable#to_set` with arguments is deprecated:
```bash
grep -r "\.to_set\(" app/ lib/ --include="*.rb"
```

```ruby
# ⚠️ Deprecated in Ruby 4.0 (will be removed in Ruby 4.1+)
[1, 2, 3].to_set { |x| x * 2 }

# ✅ Fix NOW (works in Ruby 3.x and 4.0)
[1, 2, 3].map { |x| x * 2 }.to_set
```

**Action:** If found, fix this NOW (before upgrading) - works in both Ruby 3.x and 4.0

#### Breaking Change 5: Pathname is Now a Core Class

**Impact:** `Pathname` no longer requires `require 'pathname'`

**Search for requires:**
```bash
grep -rn "require ['\"]pathname['\"]" app/ lib/ --include="*.rb"
```

**⚠️ IMPORTANT - Timing:**
- **Ruby 3.x:** Keep `require "pathname"` - REQUIRED (removing breaks code)
- **Ruby 4.0+:** Can optionally remove `require "pathname"` - purely cosmetic

**Action:**
- Do NOT remove before upgrading to Ruby 4.0
- AFTER upgrading to Ruby 4.0: Optionally remove for cleanup

#### Breaking Change 6: Binding#local_variables Changes

**Impact:** `Binding#local_variables` no longer includes numbered parameters

**Search for Binding usage:**
```bash
grep -r "Binding\." app/ lib/ --include="*.rb"
grep -r "\.local_variables" app/ lib/ --include="*.rb"
```

**Migration:**
```ruby
# Ruby 3.x
binding.local_variables  # => [:x, :y, :_1, :_2]

# Ruby 4.0
binding.local_variables           # => [:x, :y] (numbered params excluded)
binding.implicit_parameters       # => [:_1, :_2] (new method)
binding.implicit_parameter_get(:_1)  # Access numbered param
```

#### Breaking Change 7: TCPSocket Timeout Behavior

**Impact:** `IO::TimeoutError` consistently raised instead of `Errno::ETIMEDOUT`

**Search for timeout handling:**
```bash
grep -r "TCPSocket\|Socket\.tcp" app/ lib/ --include="*.rb"
grep -r "ETIMEDOUT" app/ lib/ --include="*.rb"
```

**Migration:**
```ruby
# ❌ Old error handling
begin
  TCPSocket.new(host, port, open_timeout: 5)
rescue Errno::ETIMEDOUT => e
  # Handle timeout
end

# ✅ Consistent in Ruby 4.0
begin
  TCPSocket.new(host, port, open_timeout: 5)
rescue IO::TimeoutError => e
  # Always IO::TimeoutError now
rescue Errno::ETIMEDOUT => e
  # May still happen at OS level
end
```

#### Breaking Change 8: Logical Operators Line Continuation

**Impact:** `||`, `&&`, `and`, `or` at line start now continue previous line

**Behavior:**
```ruby
# Ruby 4.0 behavior
if condition1
   && condition2  # Continues previous line
  do_something
end

# Equivalent to:
if condition1 && condition2
  do_something
end
```

**Action:** Most code already follows this pattern or won't be affected.

### Step 3: Check Gem Compatibility

**Critical gems to verify for Ruby 4.0:**
```bash
bundle list | grep -E "(rails|mysql2|pg|puma|sidekiq|nokogiri|bootsnap)"
```

**Check for native extensions:**
```bash
bundle show --paths | xargs -I {} find {} -name "*.c" -o -name "*.so" 2>/dev/null | grep -v ".bundle"
```

**Native extension gems will need recompilation on Ruby 4.0:**
- mysql2
- pg
- nokogiri
- bootsnap
- sassc

**Action:** `bundle install` will automatically recompile native extensions.

**Check gem Ruby version requirements:**
```bash
# Look for Ruby version constraints in gemspecs
bundle list | while read gem ver; do
  gem=$(echo $gem | awk '{print $2}')
  bundle info $gem 2>/dev/null | grep "Ruby:"
done
```

### Step 4: Generate Upgrade Readiness Report

Create `RUBY_4_UPGRADE_READINESS.md` with this structure:

```markdown
# Ruby 4.0 Upgrade Readiness Report

**Generated:** {{DATE}}
**Current Ruby Version:** {{RUBY_VERSION}}
**Current Rails Version:** {{RAILS_VERSION}}
**Target:** Ruby 4.0.3 (Latest Stable)
**Analysis:** Based on actual Ruby 4.0.0 breaking changes

---

## Executive Summary

| Breaking Change | Status | Issues Found | Risk |
|-----------------|--------|--------------|------|
| `*nil` Splat Behavior | {{STATUS}} | {{COUNT}} | {{RISK}} |
| Process Creation with Pipe | {{STATUS}} | {{COUNT}} | {{RISK}} |
| Ractor API Changes | {{STATUS}} | {{COUNT}} | {{RISK}} |
| Set Core Class | {{STATUS}} | {{COUNT}} | Low |
| Pathname Core Class | {{STATUS}} | {{COUNT}} | Low |
| Binding#local_variables | {{STATUS}} | {{COUNT}} | {{RISK}} |
| TCPSocket Timeout | {{STATUS}} | {{COUNT}} | {{RISK}} |

**Overall Readiness:** {{PERCENTAGE}}%

---

## 1. Breaking Change Analysis

### `*nil` Splat Operator
- **Files affected:** {{COUNT}}
- **Locations:** {{FILE_PATHS}}
- **Fix required:** {{YES/NO}}

### Process Creation with `|`
- **IO.read/write/open usage:** {{COUNT}}
- **Kernel#open with pipe:** {{COUNT}}
- **Migration needed:** {{DETAILS}}

### Ractor Usage
- **Ractor.yield/take:** {{COUNT}}
- **Migration to Ractor::Port:** {{YES/NO}}

### Set/Pathname Requires
- **require "set":** {{COUNT}} files (cleanup recommended)
- **require "pathname":** {{COUNT}} files (cleanup recommended)

### Binding Usage
- **Binding#local_variables:** {{COUNT}}
- **Impact:** {{DETAILS}}

### Socket Timeout Handling
- **TCPSocket usage:** {{COUNT}}
- **Errno::ETIMEDOUT rescue:** {{COUNT}}
- **Update needed:** {{YES/NO}}

---

## 2. Gem Compatibility

### Native Extension Gems

| Gem | Version | Ruby 4.0 Status | Action |
|-----|---------|-----------------|--------|
| {{GEM}} | {{VERSION}} | {{STATUS}} | {{ACTION}} |

### Critical Dependencies

| Gem | Version | Ruby 4.0 Status | Notes |
|-----|---------|-----------------|-------|
| rails | {{VERSION}} | {{STATUS}} | {{NOTES}} |
| {{...}} | {{...}} | {{...}} | {{...}} |

---

## 3. Recommended Actions

### High Priority (Must Fix Before Upgrade)

1. **{{ISSUE}}**
   - Location: {{FILE}}:{{LINE}}
   - Fix: {{SOLUTION}}

### Medium Priority (Cleanup Recommended)

1. **Remove `require "set"`**
   - Files: {{LIST}}
   - Action: Delete lines

### Low Priority (Optional)

1. **{{OPTIONAL_ITEM}}**

---

## 4. Migration Steps

### Phase 1: Pre-Upgrade

1. Fix all high-priority issues
2. Update gems: `bundle update`
3. Run tests: `bundle exec rspec`

### Phase 2: Upgrade Ruby

```bash
# Using rbenv
rbenv install 4.0.3
rbenv local 4.0.3

# Reinstall gems
bundle install

# Recompile native extensions
bundle pristine
```

### Phase 3: Testing

1. Run full test suite
2. Check for new warnings
3. Performance benchmarks

### Phase 4: Deployment

1. Deploy to staging
2. Canary deployment (10%)
3. Full production rollout

---

## 5. Estimated Effort

| Task | Hours | Priority |
|------|-------|----------|
| Fix breaking changes | {{HOURS}} | High |
| Update gems | {{HOURS}} | High |
| Testing | {{HOURS}} | High |
| Deployment | {{HOURS}} | Medium |
| **Total** | **{{TOTAL}}** | - |

---

## 6. Risk Assessment

**Overall Risk:** {{Low/Medium/High}}

**High Risk Areas:**
- {{AREA}}

**Medium Risk Areas:**
- {{AREA}}

**Low Risk Areas:**
- {{AREA}}

---

## 7. New Features Available in Ruby 4.0

### Performance Improvements
- Improved GC
- Faster JIT compilation
- Better method dispatch

### New APIs
- `Array#rfind` - efficient reverse find
- `Enumerator.produce` with size
- `Math.log1p`, `Math.expm1`
- `String#strip` with selectors
- `Kernel#inspect` control via `#instance_variables_to_inspect`

### Ractor Enhancements
- `Ractor::Port` for communication
- `Ractor#join`, `Ractor#value`
- Improved concurrency support

---

## 8. Resources

- [Ruby 4.0.0 Release Notes](https://github.com/ruby/ruby/blob/master/doc/NEWS/NEWS-4.0.0.md)
- [Ruby 4.1.0 Changelog](https://github.com/ruby/ruby/blob/master/NEWS.md)
- [Rails Upgrade Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)

---

## 9. Next Steps

1. ⬜ Review this report with team
2. ⬜ Fix high-priority issues
3. ⬜ Update gems
4. ⬜ Test in development
5. ⬜ Deploy to staging
6. ⬜ Production upgrade

**Target Date:** {{DATE}}
```

### Step 5: Run Automated Checks

**Create a check script:**
```bash
#!/bin/bash
# ruby4_check.sh

echo "=== Ruby 4.0 Compatibility Check ==="
echo ""

echo "Current Ruby version:"
ruby -v
echo ""

echo "Checking for *nil splat:"
grep -r "\*nil" app/ lib/ --include="*.rb" || echo "✅ None found"
echo ""

echo "Checking for pipe process creation:"
grep -r 'IO\.\(read\|write\|readlines\|foreach\)\s*(\s*['"'"'"]|' app/ lib/ --include="*.rb" || echo "✅ None found"
grep -r 'open\s*(\s*['"'"'"]|' app/ lib/ --include="*.rb" || echo "✅ None found"
echo ""

echo "Checking for Ractor usage:"
grep -r "Ractor\." app/ lib/ --include="*.rb" || echo "✅ None found"
echo ""

echo "Checking for redundant requires:"
echo "Set requires:"
grep -rn "require ['\"]set['\"]" app/ lib/ --include="*.rb" || echo "✅ None found"
echo "Pathname requires:"
grep -rn "require ['\"]pathname['\"]" app/ lib/ --include="*.rb" || echo "✅ None found"
echo ""

echo "Checking for deprecated .to_set with arguments:"
grep -r "\.to_set\(" app/ lib/ --include="*.rb" || echo "✅ None found"
echo ""

echo "Native extension gems:"
bundle show --paths | xargs -I {} find {} -name "*.so" 2>/dev/null | head -5
echo ""

echo "=== Check Complete ==="
```

**Run the script:**
```bash
chmod +x ruby4_check.sh
./ruby4_check.sh
```

## Best Practices

### 1. Test Early with Ruby 4.0

```bash
# Install Ruby 4.0 in development
rbenv install 4.0.3

# Create test branch
git checkout -b ruby-4-0-test

# Update .ruby-version
echo "4.0.3" > .ruby-version

# Bundle install
bundle install

# Run tests
RUBYOPT="-W" bundle exec rspec
```

### 2. Gradual Migration

- Test in development first
- Deploy to staging
- Canary deployment in production
- Monitor metrics closely
- Keep rollback plan ready

### 3. Monitor Performance

Ruby 4.0 has performance improvements:
- 5-15% faster in benchmarks
- Better GC behavior
- Improved JIT

**Benchmark before and after:**
```ruby
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("your_method") { YourClass.your_method }
end
```

### 4. Keep Gems Updated

```bash
# Check for outdated gems
bundle outdated

# Update conservatively
bundle update --conservative

# Or update all
bundle update
```

## Common Mistakes to Avoid

- ❌ Assuming no changes needed without checking
- ❌ Not testing with actual Ruby 4.0
- ❌ Upgrading gems and Ruby simultaneously
- ❌ Skipping staging deployment
- ❌ Not monitoring after upgrade
- ❌ Ignoring native extension recompilation
- ❌ Not having rollback plan
- ❌ Rushing production deployment

## Verification Checklist

Before declaring Ruby 4.0 readiness:

- [ ] No `*nil` usage found
- [ ] No pipe-based process creation
- [ ] No old Ractor API usage
- [ ] `require "set"` cleanup complete (optional)
- [ ] `require "pathname"` cleanup complete (optional)
- [ ] All tests pass on Ruby 4.0
- [ ] No deprecation warnings
- [ ] Gem compatibility verified
- [ ] Native extensions recompiled
- [ ] Performance benchmarks acceptable
- [ ] Staging deployment successful
- [ ] Rollback plan tested
- [ ] Team trained on changes

## Historical Context

**Ruby 3.0 → 4.0 is a smaller jump than 2.7 → 3.0:**

- Keyword argument separation was the biggest Ruby 3.0 change
- Ruby 4.0 removes long-deprecated features
- Most breaking changes affect edge cases
- Well-maintained gems already Ruby 4.0 compatible

**Expected Ruby 4.0 adoption:**
- Rails 8.x fully supports Ruby 4.0
- Major gems updated quickly
- Production adoption ramping up

## Support

If you encounter issues:

1. Check [Ruby Issue Tracker](https://bugs.ruby-lang.org)
2. Review [Rails Upgrading Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
3. Search GitHub issues for your gems
4. Ask on Ruby Discord/Forums
