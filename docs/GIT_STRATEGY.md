# Git Branch Strategy

> **Version:** 1.0.0  
> **Date:** 2026-07-24  
> **Status:** Active

---

## Branch Strategy

This document defines the Git branching strategy for the SAEQ project.

### Branch Types

#### 1. `main` (Production Branch)

**Purpose:** Production-ready code that is deployed to production environments.

**Protection Rules:**
- Require pull request before merging
- Require at least 1 approval
- Require status checks to pass (CI/CD)
- Require branches to be up to date
- Do not allow direct pushes
- Do not allow force pushes

**Naming:** `main`

**Deployment:** Automatic deployment to production on merge

---

#### 2. `develop` (Integration Branch)

**Purpose:** Integration branch for features before they are released to production.

**Protection Rules:**
- Require pull request before merging
- Require at least 1 approval
- Require status checks to pass
- Do not allow force pushes

**Naming:** `develop`

**Deployment:** Automatic deployment to staging/development environment on merge

---

#### 3. `feature/*` (Feature Branches)

**Purpose:** Development of new features or enhancements.

**Branch Naming Convention:**
```
feature/JIRA-123-add-user-authentication
feature/JIRA-456-implement-payment-gateway
feature/update-welcome-screen
```

**Rules:**
- Branch from: `develop`
- Merge to: `develop`
- Must pass all tests before merging
- Must be up to date with `develop` before merging
- Delete after merge

**Lifetime:** Short-lived (days to 1-2 weeks maximum)

---

#### 4. `hotfix/*` (Hotfix Branches)

**Purpose:** Critical bug fixes in production.

**Branch Naming Convention:**
```
hotfix/JIRA-789-fix-crash-on-login
hotfix/security-patch-vulnerability
```

**Rules:**
- Branch from: `main`
- Merge to: `main` AND `develop`
- Must pass all tests before merging
- Must be reviewed by senior developer
- Delete after merge

**Lifetime:** Very short-lived (hours to 1 day)

---

## Workflow

### Feature Development Workflow

```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/JIRA-123-add-user-authentication

# 2. Develop and commit
git add .
git commit -m "feat(auth): add login form validation"

# 3. Push and create PR
git push origin feature/JIRA-123-add-user-authentication
# Create PR to merge into develop

# 4. After PR approval and merge, delete branch
git branch -d feature/JIRA-123-add-user-authentication
```

### Hotfix Workflow

```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/JIRA-789-fix-crash-on-login

# 2. Fix and commit
git add .
git commit -m "fix(login): prevent crash on empty credentials"

# 3. Push and create PRs
git push origin hotfix/JIRA-789-fix-crash-on-login
# Create PR to merge into main
# Create PR to merge into develop

# 4. After merge, delete branch
git branch -d hotfix/JIRA-789-fix-crash-on-login
```

---

## Commit Message Convention

This project follows **Conventional Commits** specification.

### Format

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Types

- **feat:** A new feature
- **fix:** A bug fix
- **docs:** Documentation only changes
- **style:** Changes that do not affect the meaning of the code (formatting, etc.)
- **refactor:** A code change that neither fixes a bug nor adds a feature
- **perf:** A code change that improves performance
- **test:** Adding missing tests or correcting existing tests
- **chore:** Changes to the build process or auxiliary tools and libraries
- **ci:** Changes to CI configuration files and scripts
- **revert:** Reverts a previous commit

### Scopes (Optional)

Common scopes for this project:
- **auth:** Authentication and authorization
- **delivery:** Delivery feature module
- **driver:** Driver feature module
- **orders:** Orders feature module
- **profile:** Profile feature module
- **api:** API client and network layer
- **core:** Core infrastructure (services, providers, theme)
- **shared:** Shared widgets and utilities
- **test:** Test files and infrastructure
- **docs:** Documentation
- **deps:** Dependencies (pubspec.yaml)
- **ci:** CI/CD configuration

### Subject

- Use imperative mood: "add" not "added" or "adds"
- Don't capitalize first letter
- No period at the end
- Maximum 50 characters

### Body (Optional)

- Use imperative mood
- Explain motivation for the change
- Contrast with previous behavior
- Wrap at 72 characters

### Footer (Optional)

- Reference issues: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`

### Examples

```bash
# Simple commit
git commit -m "feat(auth): add login screen"

# With scope and description
git commit -m "feat(driver): implement welcome screen with localization support

Adds a new welcome screen for the driver feature with Arabic and English
localization support. Includes app name, tagline, and navigation to
architecture overview.

Closes #42"

# Breaking change
git commit -m "feat(api)!: migrate to Dio 5.0

BREAKING CHANGE: Dio client now requires base URL configuration.
Update all API calls to use the new base URL parameter.

Closes #89"
```

---

## Pull Request Guidelines

### PR Title Format

```
[Type] Short description
```

Examples:
- `[Feat] Add user authentication flow`
- `[Fix] Resolve crash on welcome screen`
- `[Docs] Update API documentation`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
Closes #123
Related to #456

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

---

## CI/CD Integration

### Required Status Checks

Before merging to `main` or `develop`, the following checks must pass:

1. **flutter analyze** - No errors or warnings
2. **flutter test** - All tests pass
3. **flutter build** - Successful build for target platform
4. **Code coverage** - Minimum 70% coverage (future)

### Branch Protection

```yaml
# .github/branch-protection.yml (example)
main:
  required_status_checks:
    - flutter_analyze
    - flutter_test
    - flutter_build_android
    - flutter_build_ios
  enforce_admins: false
  required_pull_request_reviews:
    required_approving_review_count: 1
    dismiss_stale_reviews: true
  restrictions:
    - push: false
    - force_push: false
```

---

## Tags and Releases

### Tag Naming

```
v1.0.0
v1.0.1
v1.1.0
```

Follows Semantic Versioning (SemVer):
- **MAJOR:** Incompatible API changes
- **MINOR:** Add functionality (backwards-compatible)
- **PATCH:** Bug fixes (backwards-compatible)

### Release Process

1. Create release branch from `main`: `release/v1.2.0`
2. Final testing and bug fixes on release branch
3. Merge release branch to `main`
4. Tag the release: `git tag -a v1.2.0 -m "Release version 1.2.0"`
5. Push tag: `git push origin v1.2.0`
6. Merge release branch to `develop`
7. Delete release branch

---

## Emergency Procedures

### Hotfix Process

For critical production issues:

1. Create hotfix branch from `main`
2. Implement fix with minimal changes
3. Fast-track PR review (1 approval minimum)
4. Merge to `main` and tag new patch version
5. Merge to `develop` immediately
6. Deploy to production

### Rollback Process

If a release causes critical issues:

```bash
# Revert the merge commit
git revert -m 1 <merge-commit-hash>

# Push to main
git push origin main

# Tag the rollback
git tag -a v1.2.1-rollback -m "Rollback to v1.2.0"
git push origin v1.2.1-rollback
```

---

## Best Practices

1. **Keep branches short-lived** - Merge within 1-2 weeks
2. **Rebase regularly** - Keep feature branches up to date with `develop`
3. **Write meaningful commit messages** - Follow Conventional Commits
4. **Small, focused PRs** - One feature/fix per PR
5. **Review code** - All PRs require review
6. **Test before merge** - All tests must pass
7. **Delete merged branches** - Keep repository clean
8. **Use issue tracking** - Link commits and PRs to issues

---

## Tools and Automation

### Recommended Tools

- **Git Hooks:** Husky or pre-commit
- **Commit Linting:** commitlint
- **Branch Naming:** git-flow or custom scripts
- **PR Templates:** GitHub PR templates
- **CI/CD:** GitHub Actions

### Git Hooks Setup (Future)

```bash
# Install husky
npm install -g husky
npx husky install

# Add pre-commit hook
npx husky add .husky/pre-commit "flutter analyze"
npx husky add .husky/pre-commit "flutter test"
```

---

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Semantic Versioning](https://semver.org/)