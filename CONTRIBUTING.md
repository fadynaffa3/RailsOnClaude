# Contributing to RailsOnClaude

Thank you for your interest in contributing! This document provides guidelines for contributing new skills or improving existing ones.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest enhancements
- Provide clear, detailed descriptions
- Include code examples when relevant

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-skill`)
3. Make your changes
4. Test your changes locally
5. Commit with clear messages
6. Push to your fork
7. Submit a Pull Request

## Adding New Skills

### Skill Structure

Each skill must follow this structure:

```
skills/
└── your-skill-name/
    ├── SKILL.md              # Main skill file with YAML frontmatter (required)
    ├── README.md             # Usage documentation (optional)
    ├── agents/               # Subagent definitions (optional)
    │   └── *.md
    ├── references/           # Reference materials (optional)
    │   └── *.md
    └── scripts/              # Helper scripts (optional)
        └── *.sh
```

### SKILL.md Requirements

Every skill MUST have a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: your-skill-name
description: Clear, concise description of what the skill does and when to use it. This helps AI agents determine when to invoke the skill.
category: code-quality|language-expertise|framework-expertise|testing|security
---

# Skill Title

Clear instructions for the AI agent to follow.

## Use this skill when

- Specific scenario 1
- Specific scenario 2

## Do not use this skill when

- Scenario where it's not appropriate

## Instructions

Step-by-step instructions...
```

### Skill Categories

- **code-quality**: Code audits, linting, refactoring
- **language-expertise**: Ruby language guidance
- **framework-expertise**: Rails framework guidance
- **testing**: Test writing, coverage analysis
- **security**: Security scanning, vulnerability detection
- **performance**: Optimization, profiling

### Naming Conventions

- Use kebab-case for skill names (e.g., `rails-audit`, `ruby-help`)
- Keep names short and descriptive
- Avoid redundant prefixes (e.g., prefer `audit` over `rails-audit-skill`)

## Testing Your Skill

### Local Testing

Test your skill locally before submitting:

```bash
# Navigate to skill directory
cd skills/your-skill-name

# Test with npx skills (if available)
npx skills add .

# Or copy to Claude Code for testing
cp -r . ~/.claude/skills/your-skill-name
```

### Test in Claude Code

```
/your-skill-name
```

Verify:
- Skill is invoked correctly
- Instructions are clear and actionable
- Output is as expected
- Edge cases are handled

## Code Quality Standards

### Markdown

- Use clear, concise language
- Include code examples with proper syntax highlighting
- Use headers for organization
- Keep lines under 120 characters when possible

### Documentation

- All skills must have a description in SKILL.md frontmatter
- Complex skills should include a README.md
- Reference materials should be in the `references/` directory
- Include examples and use cases

### Ruby Code (if included)

- Follow Ruby community style guide
- Use RuboCop for linting
- Include comments for complex logic
- Prefer idiomatic Ruby

## Skill Quality Checklist

Before submitting a skill, verify:

- [ ] SKILL.md has required YAML frontmatter
- [ ] Description is clear and specific
- [ ] Instructions are actionable and step-by-step
- [ ] Skill has been tested locally
- [ ] Documentation is complete
- [ ] Examples are included
- [ ] Code follows style guidelines
- [ ] No sensitive information (API keys, credentials)
- [ ] License is compatible (MIT)

## Reference Materials

### Good Examples

Look at existing skills for examples:
- `skills/rails-audit/` - Complex skill with subagents and references
- `skills/ruby-help/` - Simple guidance skill
- `skills/rails-help/` - Framework expertise skill

### YAML Frontmatter Best Practices

```yaml
---
name: skill-name                    # Use kebab-case
description: >                      # Use > for multi-line descriptions
  Comprehensive description that helps agents
  understand when to use this skill.
category: code-quality              # Pick one category
tags: [rails, ruby, testing]        # Optional: additional tags
---
```

## Bundles

If your skill fits into a role-based bundle, add it to the appropriate bundle in `bundles/`:

```markdown
# bundles/your-bundle/README.md

## Included Skills

- **your-skill** - Brief description
```

## Workflow Integration

If your skill is part of a common workflow, consider adding a workflow document in `workflows/`:

```markdown
# workflows/your-workflow.md

## Steps

1. Run `/skill-one`
2. Review output
3. Run `/skill-two`
```

## Review Process

Pull requests will be reviewed for:

1. **Functionality**: Does the skill work as intended?
2. **Quality**: Is the code/documentation well-written?
3. **Usefulness**: Does it solve a real problem?
4. **Compatibility**: Works with Claude Code, Cursor, etc.
5. **Standards**: Follows contributing guidelines

## Community Guidelines

- Be respectful and constructive
- Welcome newcomers
- Share knowledge freely
- Give credit where due
- Follow the Code of Conduct

## Questions?

- Open a GitHub Discussion for general questions
- Open an Issue for bugs or feature requests
- Tag maintainers for urgent matters

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to RailsOnClaude! 🛤️
