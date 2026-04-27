# Publishing RailsOnClaude

Step-by-step guide to publish your skills to the npx skills ecosystem and GitHub.

## Pre-Publishing Checklist

Before publishing, verify:

- [ ] All skills have valid SKILL.md with YAML frontmatter
- [ ] README.md is complete and accurate
- [ ] CONTRIBUTING.md and TESTING.md are in place
- [ ] package.json has correct information
- [ ] LICENSE file exists (MIT)
- [ ] No sensitive information (API keys, credentials)
- [ ] All skills tested locally
- [ ] Git repository is initialized
- [ ] .gitignore is configured

## Step 1: Test Locally

Test each skill before publishing:

```bash
# Test rails-audit
cd skills/rails-audit
npx skills add .
# Select your AI tool (Claude Code, Cursor, etc.)
# Test in a Rails project: /rails-audit

# Test ruby-help
cd ../ruby-help
npx skills add .
# Test: /ruby-help

# Test rails-help
cd ../rails-help
npx skills add .
# Test: /rails-help
```

**Verify:**
- Skills install without errors
- Skills are invoked correctly
- Output is as expected

## Step 2: Update Package.json

Update `package.json` with your GitHub username:

```json
{
  "repository": {
    "type": "git",
    "url": "https://github.com/YOUR_ACTUAL_USERNAME/RailsOnClaude.git"
  },
  "homepage": "https://github.com/YOUR_ACTUAL_USERNAME/RailsOnClaude#readme",
  "bugs": {
    "url": "https://github.com/YOUR_ACTUAL_USERNAME/RailsOnClaude/issues"
  }
}
```

Also update README.md URLs.

## Step 3: Commit All Changes

```bash
cd ~/work/RailsOnClaude

# Review changes
git status

# Add all files
git add .

# Commit
git commit -m "Prepare for publishing: Add package.json, docs, and npx support

- Added package.json with skills registry
- Added CONTRIBUTING.md with skill development guidelines
- Added TESTING.md with testing procedures
- Added PUBLISHING.md with publishing guide
- Updated README.md with npx installation instructions
- Configured .gitignore and .npmrc

Ready for npx skills ecosystem"

# View commit
git log -1 --stat
```

## Step 4: Create GitHub Repository

### Option A: GitHub CLI

```bash
# Create public repository
gh repo create RailsOnClaude --public --source=. --remote=origin

# Push to GitHub
git push -u origin master
```

### Option B: GitHub Web UI

1. Go to https://github.com/new
2. Repository name: `RailsOnClaude`
3. Description: `Curated collection of AI assistant skills for Ruby on Rails development`
4. Public repository
5. Don't initialize with README (you already have one)
6. Click "Create repository"

Then push:

```bash
git remote add origin https://github.com/fadynaffa3/RailsOnClaude.git
git branch -M main
git push -u origin main
```

## Step 5: Configure GitHub Repository

### Add Topics

In GitHub repository settings, add topics:
- `rails`
- `ruby`
- `claude-code`
- `cursor`
- `ai-assistant`
- `skills`
- `code-quality`
- `npx-skills`

### Update README Badges

Add badges to README.md:

```markdown
[![NPM](https://img.shields.io/badge/npx-skills-blue)](https://skills.sh)
[![GitHub Stars](https://img.shields.io/github/stars/fadynaffa3/RailsOnClaude)](https://github.com/fadynaffa3/RailsOnClaude)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

### Enable GitHub Pages (Optional)

For documentation hosting:

1. Go to Settings → Pages
2. Source: Deploy from branch
3. Branch: main / docs (or root)
4. Save

## Step 6: Test NPX Installation

Test that others can install your skills:

```bash
# From a different directory
cd ~

# Install all skills
npx skills add fadynaffa3/RailsOnClaude

# Or install individual skill
npx skills add fadynaffa3/RailsOnClaude/skills/rails-audit
```

**Verify:**
- Installation succeeds
- Skills appear in `~/.claude/skills/` (or appropriate directory)
- Skills can be invoked

## Step 7: Announce and Share

### Skills.sh Discovery

Your skills will automatically appear on [Skills.sh](https://skills.sh) once people start installing them. No manual submission needed!

### Share on Social Media

Example announcement:

```
🚀 Just published "RailsOnClaude" - a collection of AI assistant skills for Ruby on Rails development!

✨ Features:
- Comprehensive code audits with SimpleCov & RubyCritic
- Ruby idioms and best practices
- Rails conventions and patterns

Install via npx:
npx skills add fadynaffa3/RailsOnClaude

GitHub: https://github.com/fadynaffa3/RailsOnClaude

#RubyOnRails #AI #ClaudeCode #Cursor
```

### Share in Communities

- Dev.to
- Reddit r/rails
- Ruby Weekly newsletter
- Rails Forum
- Twitter/X
- LinkedIn

## Step 8: Maintenance

### Versioning

Update version in `package.json` for releases:

```bash
# After making changes
npm version patch  # 1.0.0 → 1.0.1
npm version minor  # 1.0.1 → 1.1.0
npm version major  # 1.1.0 → 2.0.0

git push --tags
```

### GitHub Releases

Create releases for major updates:

```bash
# Tag a release
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0

# Or use GitHub CLI
gh release create v1.0.0 --title "v1.0.0 - Initial Release" --notes "First stable release"
```

### Keep Dependencies Updated

No npm dependencies in this repo, but keep reference materials current:
- Ruby version updates
- Rails version updates
- Security best practices
- New patterns and idioms

## Post-Publishing Checklist

After publishing:

- [ ] Repository is public on GitHub
- [ ] README.md URLs are correct
- [ ] Installation via npx works
- [ ] Skills appear in Skills.sh (after first installs)
- [ ] GitHub topics are set
- [ ] License is visible
- [ ] Issues and Discussions are enabled
- [ ] Announced in relevant communities

## Troubleshooting

### NPX Install Fails

**Issue:** `npx skills add fadynaffa3/RailsOnClaude` fails

**Solutions:**
1. Verify repository is public
2. Check URL is correct
3. Ensure SKILL.md files have valid YAML frontmatter
4. Try installing a single skill first

### Skills Not Appearing

**Issue:** Skills don't show up after installation

**Solutions:**
1. Check installation directory: `~/.claude/skills/`
2. Restart Claude Code or Cursor
3. Verify SKILL.md frontmatter `name:` field
4. Check for errors in YAML parsing

### Skills.sh Not Showing

**Issue:** Skills don't appear on Skills.sh

**Explanation:** Skills.sh discovers skills as they get installed. It may take:
- Multiple installations by different users
- Some time to index
- Be patient - it's automatic!

## Getting Help

If you encounter issues:

1. Check [npx skills documentation](https://skills.sh)
2. Review other successful skill repositories
3. Open a GitHub Issue
4. Ask in Claude Code Discord
5. Search existing discussions

## Success Metrics

Track your skills' success:

- GitHub Stars ⭐
- Fork count 🍴
- Issue engagement 💬
- Install count (if tracked)
- Community feedback 📣

## Next Steps

After successful publishing:

1. **Monitor Issues:** Respond to user feedback
2. **Add Skills:** Continue adding new skills
3. **Improve Docs:** Enhance documentation based on questions
4. **Engage Community:** Help users in discussions
5. **Keep Updated:** Maintain skills as Rails/Ruby evolve

---

Congratulations on publishing your skills! 🎉

The Rails community thanks you for your contribution! 🛤️
