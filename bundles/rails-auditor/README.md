# Rails Code Auditor Bundle

Comprehensive code quality, security, and best practices audit skills.

## Included Skills

- **rails-audit** - Comprehensive Rails code audits with test coverage and security scanning
- **ruby-help** - Ruby best practices and code quality patterns

## Installation

```bash
# From RailsOnClaude root
cp -r skills/rails-audit ~/.claude/skills/
cp -r skills/ruby-help ~/.claude/skills/

# Or use the install script
bash bundles/rails-auditor/install.sh
```

## Use Cases

- Pre-production code audits
- Security vulnerability assessment
- Technical debt identification
- Code review automation
- Quality assurance before major releases
- Compliance and security audits

## Recommended Workflow

1. Run `/rails-audit` for comprehensive analysis
2. Review generated `RAILS_AUDIT_REPORT.md`
3. Use `/ruby-help` for refactoring guidance on Ruby-specific issues
4. Focus on Critical and High severity issues first
5. Create Linear issues for Medium/Low severity items
6. Re-run audit after fixes to verify improvements

## Audit Categories

The audit analyzes:

- **Testing**: Coverage metrics, missing tests, test quality
- **Security**: SQL injection, XSS, mass assignment vulnerabilities
- **Models**: Fat models, callback complexity, Law of Demeter violations
- **Controllers**: Fat controllers, business logic leakage
- **Code Design**: PORO patterns, service objects, SRP violations
- **Database**: Missing indexes, N+1 queries, migration issues
- **Performance**: Caching opportunities, query optimization

## Additional Recommendations

Consider adding:
- **sentry-setup** - For production monitoring and error tracking
- Security scanning tools (coming soon)
