## Description
<!-- Provide a clear and concise description of your changes -->


## Type of Change
<!-- Mark the relevant option with an 'x' -->

- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🔧 Configuration change
- [ ] ♻️ Code refactoring (no functional changes)
- [ ] ✅ Test addition or update
- [ ] 🎨 UI/UX improvement

## Semantic Versioning Label
<!-- REQUIRED: Add one semantic version label to your PR -->
<!-- This determines the next version number in the release -->

- [ ] `semver:patch` - Bug fixes, documentation updates, minor changes (0.0.X)
- [ ] `semver:minor` - New features, non-breaking changes (0.X.0)
- [ ] `semver:major` - Breaking changes, major refactoring (X.0.0)

**Note:** Add the label in GitHub UI after creating the PR. The release workflow requires this label.

## Changes Made
<!-- List the specific changes in this PR -->

- 
- 
- 

## Related Issues
<!-- Link to related issues using #issue-number -->

Closes #
Related to #

## Testing Checklist
<!-- Mark completed items with an 'x' -->

### Code Quality
- [ ] Code follows the project's style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] No unnecessary console logs or debug code

### Terraform Validation
- [ ] `terraform fmt -recursive` applied successfully
- [ ] `terraform validate` passes in both modules
- [ ] No new linting warnings from TFLint
- [ ] No security issues from Trivy scan

### Testing
- [ ] Unit tests added/updated and passing
- [ ] Integration tests pass (if applicable)
- [ ] YAML configuration syntax validated
- [ ] Pre-commit hooks pass locally

### Documentation
- [ ] README.md updated (if needed)
- [ ] CHANGELOG.md will be auto-updated by release workflow
- [ ] Examples updated (if functionality changed)
- [ ] Variable descriptions are clear and accurate

### Module-Specific (check if applicable)

#### tenant-config-project Changes
- [ ] YAML schema changes documented
- [ ] Local value transformations tested
- [ ] Team/project naming conventions maintained
- [ ] Variable validation blocks tested

#### bu-control-workspace Changes
- [ ] Workspace YAML schema changes documented
- [ ] GitHub integration tested
- [ ] VCS connection logic validated
- [ ] Variable set mapping tested

## Breaking Changes
<!-- If this is a breaking change, describe the impact and migration path -->

**Does this PR introduce breaking changes?** 
- [ ] Yes
- [ ] No

<!-- If yes, explain: -->
**Impact:**


**Migration guide:**


## Screenshots/Examples
<!-- If applicable, add screenshots or configuration examples -->

**Before:**
```hcl
# Paste relevant 'before' configuration
```

**After:**
```hcl
# Paste relevant 'after' configuration
```

## Deployment Notes
<!-- Any special considerations for deployment? -->

- [ ] No special deployment steps required
- [ ] Requires manual intervention (explain below)
- [ ] Requires environment variable changes
- [ ] Requires state migration

**Special instructions:**


## Reviewer Checklist
<!-- For reviewers - do not edit -->

### Code Review
- [ ] Code changes are logical and well-structured
- [ ] No hardcoded credentials or sensitive data
- [ ] Error handling is appropriate
- [ ] Code is maintainable and follows best practices

### Terraform Review
- [ ] Resources use correct naming conventions
- [ ] for_each and count logic is correct
- [ ] Dependencies are properly managed
- [ ] Outputs are comprehensive and documented

### Security Review
- [ ] No security vulnerabilities introduced
- [ ] Sensitive variables marked correctly
- [ ] Access controls are appropriate
- [ ] Secrets management is secure

### Documentation Review
- [ ] Documentation is clear and accurate
- [ ] Examples are working and relevant
- [ ] Comments explain complex logic
- [ ] README reflects current functionality

## Additional Context
<!-- Add any other context about the PR here -->


---

## Post-Merge Checklist
<!-- These will be completed after merge -->

- [ ] Release workflow creates new version tag
- [ ] CHANGELOG.md automatically updated
- [ ] GitHub release created with notes
- [ ] Documentation site updated (if applicable)
- [ ] Notify team in relevant channels

---

**By submitting this PR, I confirm that:**
- [ ] I have read and followed the contributing guidelines
- [ ] My code follows the project's code style
- [ ] I have performed a self-review of my changes
- [ ] I have added appropriate semantic version label
- [ ] I have tested my changes thoroughly
