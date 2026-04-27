---
name: rails-audit
description: Comprehensive code audit for Ruby on Rails applications covering testing, security, architecture, performance, Ruby idioms, Rails conventions, and code quality. Analyzes RSpec/Minitest tests, security vulnerabilities (SQL injection, XSS, mass assignment), code design (PORO patterns, SOLID principles), ActiveRecord optimization, N+1 queries, metaprogramming patterns, and database design. Outputs detailed audit report with automated metrics from SimpleCov (coverage) and RubyCritic (complexity). Severity-ranked findings (Critical, High, Medium, Low) with actionable refactoring recommendations.
---

# Rails Audit - Complete Code Quality Assessment

Perform comprehensive Ruby on Rails application audits combining:

- **Ruby Best Practices**: Idiomatic code, metaprogramming patterns, performance optimization
- **Rails Conventions**: MVC architecture, ActiveRecord patterns, RESTful design
- **Code Quality**: Complexity metrics, duplication detection, code smells
- **Security**: OWASP top 10 vulnerabilities, authentication/authorization issues
- **Testing**: Coverage analysis, test quality, TDD/BDD practices
- **Performance**: N+1 queries, caching opportunities, database optimization
- **Architecture**: PORO patterns, SOLID principles, service object anti-patterns

## Audit Scope

The audit can be run in two modes:
1. **Full Application Audit**: Analyze entire Rails application
2. **Targeted Audit**: Analyze specific files or directories

## Execution Flow

### Step 1: Determine Audit Scope

Ask user or infer from request:
- Full audit: Analyze all of `app/`, `spec/` or `test/`, `config/`, `db/`, `lib/`
- Targeted audit: Analyze specified paths only

### Step 2: Collect Optional Metrics (SimpleCov + RubyCritic)

Ask the user **both questions upfront** in a single `AskUserQuestion` so they can decide once:
- **Question**: "Before starting the audit, would you like to collect automated metrics?\n\n1. **SimpleCov** — runs your test suite to capture actual code coverage percentages\n2. **RubyCritic** — analyzes code complexity, duplication, and smells (does not run tests)\n\nBoth are recommended for the most thorough audit."
- **Options**: "Yes to both (Recommended)" / "SimpleCov only" / "RubyCritic only" / "Skip both"

Based on the user's choice, spawn the accepted subagents **in parallel** using the Task tool. Both can run at the same time because SimpleCov modifies the test helper while RubyCritic only reads source files — they don't conflict.

**SimpleCov subagent** (if accepted):

> Read the file `agents/simplecov_agent.md` and follow all steps described in it. The audit scope is: {{SCOPE from Step 1}}. Return the coverage data in the output format specified in that file.

**RubyCritic subagent** (if accepted):

> Read the file `agents/rubycritic_agent.md` and follow all steps described in it. The audit scope is: {{SCOPE from Step 1}}. Return the code quality data in the output format specified in that file.

**After both agents finish**, clean up:
- If SimpleCov ran: `rm -rf coverage/`
- If RubyCritic ran: `rm -rf tmp/rubycritic/`

**Interpreting responses:**
- `COVERAGE_FAILED` / `RUBYCRITIC_FAILED`: no data for that tool — use estimation mode (SimpleCov) or omit the section (RubyCritic). Note the failure reason in the report.
- `COVERAGE_DATA`: parse and keep in context for Steps 4 and 5 (overall coverage, per-directory breakdowns, lowest-coverage files, zero-coverage files).
- `RUBYCRITIC_DATA`: parse and keep in context for Steps 4 and 5 (overall score, per-directory ratings, worst-rated files, top smells, most complex files).

### Step 3: Load Reference Materials

Before analyzing, read the relevant reference files:
- `references/code_smells.md` - Code smell patterns to identify
- `references/testing_guidelines.md` - Testing best practices
- `references/poro_patterns.md` - PORO and ActiveModel patterns
- `references/security_checklist.md` - Security vulnerability patterns
- `references/rails_antipatterns.md` - Rails-specific antipatterns (external services, migrations, performance)
- `references/ruby_idioms.md` - Ruby best practices and idiomatic code patterns
- `references/rails_conventions.md` - Rails conventions, RESTful patterns, and framework best practices

### Step 4: Analyze Code by Category

Analyze in this order:

1. **Testing Coverage & Quality**
   - If SimpleCov data was collected in Step 2, use actual coverage percentages instead of estimates
   - Cross-reference per-file SimpleCov data: files with 0% coverage = "missing tests"
   - Check for missing test files
   - Identify untested public methods
   - Review test structure (Four Phase Test)
   - Check for testing antipatterns

2. **Security Vulnerabilities**
   - SQL injection risks
   - Mass assignment vulnerabilities
   - XSS vulnerabilities
   - Authentication/authorization issues
   - Sensitive data exposure

3. **Models & Database**
   - Fat model detection
   - Missing validations
   - N+1 query risks
   - Callback complexity
   - Law of Demeter violations (voyeuristic models)
   - If RubyCritic data was collected, flag models with D/F ratings or high complexity

4. **Controllers**
   - Fat controller detection
   - Business logic in controllers
   - Missing strong parameters
   - Response handling
   - Monolithic controllers (non-RESTful actions, > 7 actions)
   - Bloated sessions (storing objects instead of IDs)
   - If RubyCritic data was collected, flag controllers with D/F ratings or high complexity

5. **Code Design & Architecture**
   - Service Objects → recommend PORO refactoring
   - Large classes
   - Long methods
   - Feature envy
   - Law of Demeter violations
   - Single Responsibility violations
   - If RubyCritic data was collected, cross-reference D/F rated files and high-complexity files with manual code review findings

6. **Views & Presenters**
   - Logic in views (PHPitis)
   - Missing partials for DRY
   - Helper complexity
   - Query logic in views

7. **External Services & Error Handling**
   - Fire and forget (missing exception handling for HTTP calls)
   - Sluggish services (missing timeouts, synchronous calls that should be backgrounded)
   - Bare rescue statements
   - Silent failures (save without checking return value)

8. **Database & Migrations**
   - Messy migrations (model references, missing down methods)
   - Missing indexes on foreign keys, polymorphic associations, uniqueness validations
   - Performance antipatterns (Ruby iteration vs SQL queries)
   - Bulk operations without transactions

9. **Ruby Idioms & Best Practices**
   - Non-idiomatic Ruby code (verbose blocks, unnecessary variables)
   - Ruby 3.x features not utilized (pattern matching, endless methods, shorthand hash syntax)
   - Inefficient enumerables (use of `each` instead of `map`, `select`, etc.)
   - Improper exception handling (bare `rescue`, rescuing `Exception`)
   - Missing safe navigation (`&.`)
   - Gem dependencies (outdated, unnecessary, security vulnerabilities)
   - Metaprogramming anti-patterns (excessive `method_missing`, unclear DSLs)
   - Performance issues (string concatenation in loops, inefficient algorithms)

10. **Rails Conventions & Patterns**
    - Non-RESTful routing (custom actions instead of resources)
    - Improper use of concerns (fat concerns, wrong abstraction level)
    - Background job patterns (synchronous operations that should be async)
    - Caching opportunities (fragment caching, Russian Doll caching)
    - Missing scopes on models
    - Improper use of callbacks (business logic in callbacks)
    - Asset pipeline issues (missing precompilation, inefficient loading)
    - Internationalization gaps (hardcoded strings)
    - Missing strong parameters
    - Improper session usage
    - Direct model instantiation in views

### Step 5: Generate Audit Report

Create `RAILS_AUDIT_REPORT.md` in project root with structure defined in `references/report_template.md`.

When SimpleCov coverage data was collected in Step 2, use the **SimpleCov variant** of the Testing section in the report template. When coverage data is not available, use the **estimation variant**.

When RubyCritic data was collected in Step 2b, include the **Code Quality Metrics** section in the report using the RubyCritic variant from the report template. When RubyCritic data is not available, use the **not available variant**.

## Severity Definitions

- **Critical**: Security vulnerabilities, data loss risks, production-breaking issues
- **High**: Performance issues, missing tests for critical paths, major code smells
- **Medium**: Code smells, convention violations, maintainability concerns
- **Low**: Style issues, minor improvements, suggestions

## Key Detection Patterns

### Service Object → PORO Refactoring

When you find classes in `app/services/`:
- Classes named `*Service`, `*Manager`, `*Handler`
- Classes with only `.call` or `.perform` methods
- Recommend: Rename to domain nouns, include `ActiveModel::Model`

### Fat Model Detection

Models with:
- More than 200 lines
- More than 15 public methods
- Multiple unrelated responsibilities
- Recommend: Extract to POROs using composition

### Fat Controller Detection

Controllers with:
- Actions over 15 lines
- Business logic (not request/response handling)
- Multiple instance variable assignments
- Recommend: Extract to form objects or domain models

### Missing Test Detection

For each Ruby file in `app/`:
- Check for corresponding `_spec.rb` or `_test.rb`
- Check for tested public methods
- Report untested files and methods

## Analysis Commands

Use Claude Code's built-in tools instead of shell commands — they're faster, handle permissions correctly, and give better output:

- **Find Ruby files by type**: Use the Glob tool with patterns like `app/models/**/*.rb`, `app/controllers/**/*.rb`, `app/services/**/*.rb`
- **Find test files**: Use Glob with `spec/**/*_spec.rb` or `test/**/*_test.rb`
- **Search for patterns in code**: Use the Grep tool (e.g., search for `rescue\s*$`, `\.save\b`, `params\.permit!`)
- **Read and count lines in files**: Use the Read tool to inspect files; count lines from the output
- **Find long files**: Use Glob to list all `app/**/*.rb` files, then Read each to check line count

## Report Output

Always save the audit report to `RAILS_AUDIT_REPORT.md` in the project root and present it to the user.
