---
name: rails-dead-code-finder
description: Detects unused code in Rails applications including unreferenced services, methods with zero usages, orphaned files, dead imports, and commented code. Analyzes services, models, controllers, jobs, and helpers to identify code that can be safely removed. Generates comprehensive dead code audit report with usage counts and removal recommendations.
category: code-quality
---

# Rails Dead Code Finder

Systematically identify and report dead code in Ruby on Rails applications to reduce maintenance burden and improve codebase clarity.

## Use this skill when

- Cleaning up legacy codebases
- Preparing for major refactors
- Investigating unused features
- Reducing technical debt
- Auditing code before a release
- Finding methods that were implemented but never integrated

## Do not use this skill when

- Writing new code (use rails-help)
- Optimizing performance (use rails-db-optimizer)
- Reviewing code quality (use rails-audit)
- Testing code (use rails-test-helper)

## What This Skill Detects

1. **Unused Services**: Classes in `app/services/` with zero production usages
2. **Unused Methods**: Public methods defined but never called
3. **Orphaned Files**: Files with no references anywhere in the codebase
4. **Dead Imports**: `require` statements for files that don't exist or aren't used
5. **Commented Code**: Large blocks of commented-out code
6. **Unused Background Jobs**: Job classes never enqueued
7. **Unused Helpers**: Helper methods never called in views or controllers
8. **Unused Serializers**: Serializer classes never invoked
9. **Spec-Only Code**: Code only referenced in test files (false positive check)

## Execution Flow

### Step 1: Determine Analysis Scope

Ask user or infer from request:
- **Full audit**: Analyze all of `app/services/`, `app/jobs/`, `app/helpers/`, `app/serializers/`, `lib/`
- **Targeted audit**: Analyze specific directory (e.g., `app/services/flow/`)
- **Single file audit**: Check if a specific file is used

**Default**: Full audit if not specified

### Step 2: Analyze Services Directory

For each service file in `app/services/**/*.rb`:

1. **Extract class name** from file path:
   ```ruby
   # app/services/flow/navigation_service.rb → Flow::NavigationService
   # app/services/attio/sync_service.rb → Attio::SyncService
   ```

2. **Search for usages** across production code:
   - Grep for class name: `Flow::NavigationService`
   - Grep for `.call` invocations: `NavigationService.call`
   - Exclude from search: `spec/`, `test/`, the file itself
   - Count unique files that reference it

3. **Categorize result**:
   - **In Use**: 1+ production references
   - **Spec-Only**: Only referenced in spec files (likely dead)
   - **Dead Code**: 0 references anywhere

4. **Check for indirect usages**:
   - Background jobs (e.g., `ServiceJob.perform_later(ServiceClass)`)
   - Event subscribers (e.g., `ActiveSupport::Notifications.subscribe`)
   - Dynamic invocations (e.g., `"#{service_name}".constantize.call`)

### Step 3: Analyze Background Jobs

For each job file in `app/jobs/**/*.rb`:

1. **Extract class name** from file path:
   ```ruby
   # app/jobs/google/sync_calendar_job.rb → Google::SyncCalendarJob
   ```

2. **Search for enqueue patterns**:
   - `.perform_later`
   - `.perform_now`
   - `.perform_async`
   - `.set(wait: ...).perform_later`

3. **Check scheduled jobs**:
   - Grep for Solid Queue schedule configurations
   - Check `config/initializers/` for cron-style schedules

4. **Flag as dead** if:
   - Zero enqueue calls
   - Not in scheduled job config
   - Only referenced in spec files

### Step 4: Analyze Public Methods

For files flagged as "In Use", check individual methods:

1. **Parse method definitions**:
   - Grep for `def method_name` or `def self.method_name`
   - Skip private/protected methods (focus on public API)

2. **Search for method invocations**:
   - Direct calls: `object.method_name`
   - Class method calls: `Class.method_name`
   - Symbol to_proc: `.map(&:method_name)`

3. **Flag as dead method** if:
   - Method defined but never called
   - Only called from within the same file (helper method candidate)
   - Only called in spec files

### Step 5: Analyze Helpers

For each helper file in `app/helpers/**/*.rb`:

1. **Extract method definitions**
2. **Search in views** (`app/views/**/*.erb`, `app/views/**/*.haml`)
3. **Search in controllers** (`app/controllers/**/*.rb`)
4. **Flag as unused** if no references found

### Step 6: Analyze Serializers

For each serializer in `app/serializers/**/*.rb`:

1. **Extract class name**
2. **Search for `.new` invocations**
3. **Search for render calls**: `render json: Serializer.new(object)`
4. **Flag as unused** if no usages found

### Step 7: Detect Commented Code

1. **Grep for large comment blocks** (5+ consecutive lines starting with `#`)
2. **Analyze comment content**:
   - Is it documentation? (keep)
   - Is it commented-out code? (likely dead)
3. **Report file locations** with line numbers

### Step 8: Check for Dead Imports

1. **Grep for `require` statements** in `lib/` files
2. **Check if required file exists**
3. **Check if required constant is used**
4. **Flag imports** that:
   - Require non-existent files
   - Import constants never used in file

### Step 9: Generate Dead Code Audit Report

Create `DEAD_CODE_AUDIT.md` in project root with:

```markdown
# Dead Code Audit

**Date:** YYYY-MM-DD
**Audited by:** rails-dead-code-finder skill

## Executive Summary

Found **X critical issues** with dead code:

1. ❌ **DEAD CODE**: Y services with zero usages
2. ❌ **DEAD CODE**: Z background jobs never enqueued
3. ⚠️ **UNUSED METHODS**: N public methods with zero usages
4. ⚠️ **COMMENTED CODE**: M files with commented code blocks

## Critical Findings - Services

| Service | LOC | Usages | Status | Recommendation |
|---------|-----|--------|--------|----------------|
| ServiceName | 262 | 0 | ❌ Dead | Remove (save ~500 lines with specs) |

### 1. ServiceName - DEAD CODE ❌

**Location:** `app/services/path/service_name.rb`

**Lines of code:** XXX lines

**Usages:** 0 in production code (only in its own spec)

**Purpose:** [Brief description from comments/code]

**Evidence:**
```bash
$ grep -r "ServiceName" app/ lib/ --include="*.rb"
# Returns: 0 results (only found in spec/)
```

**Test coverage:** Has comprehensive spec file with 100% coverage of unused code.

**Recommendation:** 
- **Option A (Remove):** Delete if feature is not planned
- **Option B (Integrate):** Wire up to controller/background job if needed

**Risk of removal:** LOW - No production usage, can be restored from git

**Related files:**
- `app/services/path/service_name.rb` (XXX lines)
- `spec/services/path/service_name_spec.rb` (YYY lines)
- **Total impact:** ~ZZZ lines removed

---

## Background Jobs - Never Enqueued

| Job | LOC | Enqueued By | Status |
|-----|-----|-------------|--------|
| JobName | 50 | None | ❌ Dead |

### 1. JobName - DEAD CODE ❌

**Location:** `app/jobs/path/job_name.rb`

**Enqueue patterns searched:**
- `JobName.perform_later` - 0 results
- `JobName.perform_now` - 0 results
- `JobName.set` - 0 results

**Scheduled?** No (not in Solid Queue config)

**Recommendation:** Remove if no longer needed

---

## Unused Methods

| Class | Method | Usages | Recommendation |
|-------|--------|--------|----------------|
| ClassName | method_name | 0 | Remove or make private |

### Methods with Zero Usages

**File:** `app/services/example_service.rb`

```ruby
# Line 45-60: method_name (16 lines, never called)
def method_name(param:)
  # ...
end
```

**Recommendation:** Remove or mark as private if internal helper

---

## Commented Code Blocks

| File | Lines | Content Type |
|------|-------|--------------|
| example.rb | 50-75 | Commented code (25 lines) |

**Location:** `app/models/example.rb:50-75`

```ruby
# def old_implementation
#   # 25 lines of commented code
# end
```

**Recommendation:** Remove if not needed, or document why it's kept

---

## Summary Statistics

| Category | Total | Dead | Percentage |
|----------|-------|------|------------|
| Services | X | Y | Z% |
| Jobs | A | B | C% |
| Helpers | D | E | F% |
| Serializers | G | H | I% |

**Total dead code:** ~N lines (services + specs + jobs)

---

## Recommendations

### Immediate Actions

1. ✅ Remove confirmed dead services (save ~N lines)
2. ✅ Remove unused background jobs
3. 🔄 Decide on commented code (keep or remove)
4. 🔄 Remove or make private unused methods

### Future Improvements

1. **CI Check:** Add automated dead code detection to CI pipeline
2. **Documentation:** Document where each service/job is used
3. **Code Coverage:** Focus test coverage on used code only
4. **Refactoring:** Extract large methods from bloated classes

---

## How to Remove Dead Code Safely

1. **Verify**: Double-check grep results manually
2. **Search in frontend**: Check if referenced in frontend code (if separate repo)
3. **Check config**: Look for references in `config/` files
4. **Review git history**: See when last modified and why
5. **Remove tests first**: Delete spec file, run suite to verify nothing breaks
6. **Remove source**: Delete the actual file
7. **Commit with context**: "Remove unused ServiceName (0 production usages)"

---

## Search Commands Used

```bash
# Find all services
find app/services -name "*.rb" -type f

# Check service usage
grep -rn "ServiceName" app/ lib/ --include="*.rb" --exclude-dir="spec"

# Check job enqueue calls
grep -rn "JobName.perform_" app/ lib/ --include="*.rb"

# Find commented code blocks
grep -n "^[[:space:]]*#" app/ -A 5 | grep "def\|class\|module"
```
```

## Analysis Commands

Use Claude Code's built-in tools for maximum efficiency:

### Finding Files
```
# All services
Glob: app/services/**/*.rb

# All jobs
Glob: app/jobs/**/*.rb

# All helpers
Glob: app/helpers/**/*.rb

# All serializers
Glob: app/serializers/**/*.rb
```

### Searching for Usage
```
# Search for class references (exclude specs)
Grep: 
  pattern: "ClassName"
  path: "."
  glob: "**/*.rb"
  output_mode: "files_with_matches"

# Then manually exclude spec/ results or use path: "app/"

# Search for method invocations
Grep:
  pattern: "\.method_name"
  path: "app/"
  output_mode: "content"
  -B: 2
  -A: 2
```

### Counting Lines
```
# Read file and count
Read: app/services/example_service.rb
# Count lines from output
```

### Finding Commented Code
```
Grep:
  pattern: "^[[:space:]]*#.*def\s"
  path: "app/"
  output_mode: "content"
  -B: 1
  -A: 5
```

## Important Notes

### False Positives to Check

1. **Dynamic invocations**: Code using `constantize`, `send`, or metaprogramming
2. **Event subscribers**: Handlers registered in initializers
3. **Configuration references**: Classes referenced in YAML/JSON config
4. **Rake tasks**: Services called from `lib/tasks/`
5. **Seeds/Fixtures**: Usage in `db/seeds.rb`
6. **Separate frontend**: If frontend is separate repo, it might call APIs that use the service

### When to Keep "Dead" Code

- **Seasonal features**: Used only during specific times (e.g., Black Friday promotions)
- **Admin-only features**: Rare usage patterns
- **Emergency features**: Kept for incidents (e.g., manual sync tools)
- **Beta features**: Behind feature flags
- **Documented future use**: Explicitly marked as "WIP" or "TODO"

### Safe Removal Process

1. **Create branch**: `dead-code-cleanup`
2. **Remove in small PRs**: One service per PR for easy review
3. **Run full test suite**: Ensure no hidden dependencies
4. **Check git blame**: See if recently modified (may be work-in-progress)
5. **Ask team**: Verify no one is working on related features
6. **Document in PR**: Include grep output showing zero usages

## Report Output

Always save the audit report to `DEAD_CODE_AUDIT.md` in the project root and present a summary to the user highlighting:

1. Total lines of dead code found
2. Top 3 largest dead files
3. Quick wins (small files that are definitely unused)
4. Files that need human review (potential false positives)

**Example summary:**

```
Dead Code Audit Complete!

Found 1,247 lines of dead code across 5 files:

Top findings:
1. ImportFromJsonService - 262 lines (+ 200 test lines) - SAFE TO REMOVE
2. LegacyReportGenerator - 180 lines - CHECK WITH TEAM (last modified 2 months ago)
3. UnusedHelper - 45 lines - SAFE TO REMOVE

Quick wins: 3 files (507 lines) are definitely unused and safe to remove.
Needs review: 2 files (740 lines) may have indirect usage.

Full report saved to: DEAD_CODE_AUDIT.md
```
