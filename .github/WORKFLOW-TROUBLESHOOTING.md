# GitHub Actions Workflow Troubleshooting Guide

This document explains common issues and solutions when working with the HCP Terraform onboarding module validation and release workflows.

## Table of Contents

- [Common Issues & Solutions](#common-issues--solutions)
- [Workflow Overview](#workflow-overview)
- [Testing Workflows](#testing-workflows)
- [Debugging Tips](#debugging-tips)

## Common Issues & Solutions

### Issue 1: Workflow Doesn't Run When I Push Code

**Problem**: You push commits to a branch, but the `Module Validate` workflow doesn't trigger.

**Explanation**: This is **expected behavior**. The workflow is configured to run on **Pull Request events**, not direct pushes.

```yaml
on:
  pull_request:
    paths:
      - '**.tf'
      - '**.yaml'
      - '**.yml'
      - '**.tftest.hcl'
      - '.github/workflows/module_validate.yml'
```

**Solution**: 
1. Push your changes to a feature branch
2. **Create a Pull Request** from your feature branch to `main`
3. The workflow will trigger automatically when the PR is opened or updated

**Manual Trigger**: You can also trigger the workflow manually using the Actions tab via `workflow_dispatch`.

---

### Issue 2: Missing Semantic Version Label

**Problem**: Workflow fails with error: "Required labels were not found"

**Root Cause**: Every PR must have exactly ONE semantic versioning label:
- `semver:patch` - Bug fixes, documentation updates (0.0.X)
- `semver:minor` - New features, backward compatible (0.X.0)
- `semver:major` - Breaking changes (X.0.0)

**Solution**: Add the appropriate label to your PR:

1. Navigate to your PR in GitHub
2. Click **Labels** on the right sidebar
3. Select ONE of: `semver:patch`, `semver:minor`, or `semver:major`
4. Re-run the workflow

**Label Selection Guide**:
- 🐛 **Patch**: Bug fixes, typos, documentation updates, minor refactoring
- ✨ **Minor**: New features, new YAML config options, new outputs
- 💥 **Major**: Breaking YAML structure changes, removed features, major refactoring

---

### Issue 3: Workflow Doesn't Trigger on PR

**Problem**: You created a PR, but the workflow still doesn't run.

**Root Causes**:

#### A. No Matching Files Changed
The workflow only triggers when specific file types change:
- `**.tf` - Terraform configuration files
- `**.yaml` / `**.yml` - YAML configuration files
- `**.tftest.hcl` - Terraform test files
- `.github/workflows/module_validate.yml` - The workflow file itself

**Solution**: Ensure your PR includes changes to at least one of these file types.

**Check what files will trigger the workflow:**
```bash
git diff origin/main --name-only | grep -E '\.(tf|yaml|yml|tftest\.hcl)$'
```

**Quick Fix - Add YAML Comment:**
If you only changed documentation, add a comment to a YAML file:
```bash
# Add comment to trigger workflow
echo "# Updated $(date)" >> bu-control-workspace/config/example.yaml
git add bu-control-workspace/config/example.yaml
git commit --amend --no-edit
git push --force-with-lease
```

#### B. Workflow Not in Main Branch
GitHub runs workflows based on the **workflow file in the base branch** (main), not the PR branch.

**Solution**: The workflow files must exist in the `main` branch **before** you create the PR.

---

### Issue 4: YAML Validation Failed

**Problem**: Workflow fails with "ERROR: YAML validation failed"

**Root Cause**: Invalid YAML syntax in configuration files.

**Common YAML Mistakes:**
```yaml
# ❌ WRONG - Inconsistent indentation
workspace_name: "my-app"
 workspace_description: "My app"  # Extra space

# ✅ CORRECT
workspace_name: "my-app"
workspace_description: "My app"

# ❌ WRONG - Missing quotes on values with special characters
workspace_description: Workspace for: my-app

# ✅ CORRECT
workspace_description: "Workspace for: my-app"

# ❌ WRONG - Tabs instead of spaces
variables:
	environment:  # Tab character
		value: "prod"

# ✅ CORRECT (2 spaces)
variables:
  environment:
    value: "prod"
```

**Solution - Validate YAML Locally:**
```bash
# Install yamllint
pip install yamllint

# Check all YAML files
yamllint tenant-config-project/config/*.yaml
yamllint bu-control-workspace/config/*.yaml

# Or use Python
python3 -c "import yaml; yaml.safe_load(open('config/file.yaml'))"
```

---

### Issue 5: Terraform Init Failed in tenant-config-project

**Problem**: `terraform init` fails with module source errors

**Root Cause**: Module sources reference external repositories that may be unavailable or authentication is required.

**Current Module Sources:**
```hcl
# bu-control-workspace/main.tf
module "github" {
  source = "github.com/hashi-demo-lab/terraform-github-repository-module?ref=0.5.1"
  # ...
}

module "workspace" {
  source = "github.com/hashi-demo-lab/terraform-tfe-onboarding-module?ref=0.5.7"
  # ...
}
```

**Solution A - Make Repositories Public:**
1. Ensure external module repositories are public
2. Or fork them to your organization

**Solution B - Add GitHub Token:**
```yaml
# In .github/workflows/module_validate.yml
- name: Configure Git for Private Repos
  run: |
    git config --global url."https://${{ secrets.GH_TOKEN }}@github.com/".insteadOf "https://github.com/"
```

**Solution C - Update Module Sources:**
Use Terraform Registry sources instead:
```hcl
module "workspace" {
  source  = "terraform-tfe-onboarding-module/workspace/tfe"
  version = "~> 0.5"
  # ...
}
```

---

### Issue 6: ".cache" Directory Being Tracked

**Problem**: Git is tracking hundreds of Trivy cache files in `.cache/trivy/`.

**Root Cause**: The `.cache/` directory wasn't in `.gitignore`, so Trivy's local cache got committed.

**Solution**: 
```bash
# 1. Add .cache/ to .gitignore (already done in template)
echo ".cache/" >> .gitignore

# 2. Remove from git tracking
git rm -r --cached .cache

# 3. Commit the cleanup
git add .gitignore
git commit -m "chore: ignore Trivy cache directory"
git push
```

**Prevention**: Use the provided `.gitignore` file, which already includes `.cache/`.

---

### Issue 7: TFLint Warnings Breaking Build

**Problem**: TFLint finds issues and you want to suppress them temporarily.

**Solution A - Configure TFLint Rules:**
Create `.tflint.hcl`:
```hcl
config {
  module = true
  force = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Disable specific rules
rule "terraform_naming_convention" {
  enabled = false
}

rule "terraform_unused_declarations" {
  enabled = false
}
```

**Solution B - Continue on Error:**
The workflow already uses `continue-on-error: true` for TFLint, so it reports warnings but doesn't fail the build.

---

### Issue 8: Release Workflow Not Creating Tags

**Problem**: PR merges but no release is created.

**Root Causes:**

#### A. No Semver Label
Ensure the merged PR had a `semver:patch`, `semver:minor`, or `semver:major` label.

#### B. No Matching File Changes
The release workflow only runs when `.tf` or `.yaml` files change:
```yaml
on:
  pull_request:
    types: [closed]
    paths:
      - '**.tf'
      - '**.yaml'
      - '**.yml'
```

#### C. PR Not Merged
The workflow only runs if `github.event.pull_request.merged == true`. Closed PRs without merging don't trigger releases.

**Solution**: 
```bash
# Check if workflow ran
gh run list --workflow=pr_merge.yml --limit 5

# View workflow details
gh run view <run-id>
```

---

## Workflow Overview

### Module Validate Workflow

**Triggers**: Pull requests with changes to `.tf`, `.yaml`, or `.tftest.hcl` files

**Steps**:
1. ✅ Checkout code
2. 🏷️ Check for semantic version label
3. 🔧 Setup Terraform
4. 📝 Validate `tenant-config-project/` (format, init, validate)
5. 📝 Validate `bu-control-workspace/` (format, init, validate)
6. 🔍 Run TFLint on both modules
7. 🔒 Run Trivy security scan
8. ✅ Validate YAML syntax
9. 🧪 Run unit tests (if they exist)
10. 📚 Update documentation
11. 📊 Generate validation summary

**Expected Runtime**: 2-5 minutes

### Release Workflow

**Triggers**: Pull request merge to `main` with changes to `.tf` or `.yaml` files

**Steps**:
1. ✅ Checkout code
2. 🏷️ Determine release type from PR labels
3. 📌 Get current version from git tags
4. 🔢 Calculate new version
5. 📝 Update CHANGELOG.md
6. 💾 Commit CHANGELOG changes
7. 🏷️ Create git tag
8. 📄 Generate release notes
9. 🚀 Create GitHub release
10. 📊 Generate release summary

**Expected Runtime**: 1-2 minutes

---

## Testing Workflows

### Local Pre-commit Testing

Before creating a PR, run pre-commit hooks locally:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run on all files
pre-commit run --all-files

# Run specific hook
pre-commit run terraform-fmt --all-files
```

### Local Terraform Validation

Replicate workflow validations locally:

```bash
# Validate tenant-config-project
cd tenant-config-project
terraform fmt -check -recursive
terraform init
terraform validate
cd ..

# Validate bu-control-workspace
cd bu-control-workspace
terraform fmt -check -recursive
terraform init
terraform validate
cd ..

# Run TFLint
tflint --init
tflint --recursive

# Run Trivy
trivy config .
```

### Manual Workflow Trigger

Trigger workflows manually from GitHub UI:

1. Navigate to **Actions** tab
2. Select workflow (e.g., "Module Validate")
3. Click **Run workflow**
4. Select branch
5. Click **Run workflow** button

---

## Debugging Tips

### Enable Debug Logging

Add debug environment variables to workflow steps:

```yaml
- name: Terraform Init (Debug)
  run: terraform init
  env:
    TF_LOG: DEBUG
    TF_LOG_PATH: ./terraform-debug.log
```

### Check Workflow Runs

```bash
# List recent workflow runs
gh run list --limit 10

# View specific run details
gh run view <run-id> --log

# View failed run
gh run view <run-id> --log-failed

# Re-run failed workflow
gh run rerun <run-id>
```

### View Job Summary

After workflow completion, check the **Summary** section in the Actions run for:
- Validation results table
- Release details
- Next steps

### Common Environment Variables

Available in all workflows:
- `${{ github.event.pull_request.title }}` - PR title
- `${{ github.event.pull_request.number }}` - PR number
- `${{ github.event.pull_request.user.login }}` - PR author
- `${{ github.ref }}` - Branch reference
- `${{ github.sha }}` - Commit SHA

---

## Best Practices

### Clean Testing Workflow

**Pattern for testing changes:**
```bash
# 1. Create feature branch
git checkout -b feature/add-new-workspace
git push -u origin feature/add-new-workspace

# 2. Make changes to YAML configuration
vim bu-control-workspace/config/new-app.yaml

# 3. Commit changes
git add .
git commit -m "feat: add new application workspace"
git push

# 4. Create PR with semantic version label
gh pr create --title "Add new application workspace" \
  --body "Adds workspace for new-app" \
  --label "semver:minor"

# 5. Wait for validation to pass

# 6. Merge PR
gh pr merge --squash --delete-branch

# 7. Verify release created
gh release list

# 8. Clean up local branch
git checkout main
git pull
```

### Pre-flight Checklist

Before creating a PR:
- ✅ Run `terraform fmt -recursive`
- ✅ Run `terraform validate` in both directories
- ✅ Validate YAML syntax
- ✅ Run `pre-commit run --all-files`
- ✅ Add semantic version label
- ✅ Update CHANGELOG if needed
- ✅ Test locally if possible

---

## Getting Help

### Resources
- **Repository Issues**: Report bugs or request features
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Terraform Registry**: https://registry.terraform.io/
- **HCP Terraform Docs**: https://developer.hashicorp.com/terraform/cloud-docs

### Support Channels
- **Internal**: Platform team Slack channel
- **External**: HashiCorp Community Forum
- **Documentation**: See README.md and REPOSITORY-SETUP.md

---

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Maintained By**: Platform Engineering Team
