# Platform Onboarding Module Refactoring Plan

## Overview

This document outlines the refactoring of `tenant-config-project` → `platform-onboarding` module to be Stacks-compatible and add GitHub repository creation for BU Stacks.

## Key Changes

### 1. Remove Provider Requirements
- ❌ Remove AWS provider (not needed)
- ✅ Keep TFE provider (but declared in Stack, not module)
- ✅ Add GitHub provider requirement (but declared in Stack, not module)

### 2. Add GitHub Repository Creation
- Create BU Stack repositories automatically
- Seed initial Stack configuration files
- Configure branch protection
- Set up team access

### 3. Enhance Outputs for publish_output
- Add sensitive outputs for tokens
- Add repository URLs
- Structure for upstream consumption

### 4. Simplify Dependencies
- Remove `terraform-tfe-project-team` module dependency
- Inline project/team creation logic
- Make module self-contained

## Refactored Module Structure

```
platform-onboarding/
├── main.tf                    # Core resources (teams, projects, tokens, variable sets)
├── github.tf                  # NEW: GitHub repository creation for BU Stacks
├── projects.tf                # Consumer projects (inlined from module)
├── variables.tf               # Input variables
├── outputs.tf                 # Enhanced outputs for Stacks
├── locals.tf                  # YAML processing logic
├── versions.tf                # Provider requirements (no constraints in module)
├── README.md                  # Module documentation
├── CHANGELOG.md               # Version history
├── .gitignore
├── config/                    # Example YAML configs
│   ├── finance.yaml
│   ├── engineering.yaml
│   └── sales.yaml
├── examples/
│   ├── basic/                 # Single BU example
│   └── complete/              # Multi-BU with GitHub repos
└── tests/
    └── platform_onboarding.tftest.hcl
```

## New Variables

```hcl
variable "tfc_organization_name" {
  type        = string
  description = "HCP Terraform organization name"
}

variable "business_unit" {
  type        = string
  description = "Business unit filter (optional, defaults to all)"
  default     = null
}

# NEW: GitHub repository configuration
variable "create_bu_repositories" {
  type        = bool
  description = "Create GitHub repositories for BU Stacks"
  default     = true
}

variable "github_organization" {
  type        = string
  description = "GitHub organization for BU Stack repositories"
  default     = ""
}

variable "bu_stack_template_repo" {
  type        = string
  description = "Template repository for BU Stack initialization"
  default     = "CloudbrokerAz/tfc-bu-stack-template"
}

variable "bu_stack_repo_prefix" {
  type        = string
  description = "Prefix for BU Stack repository names"
  default     = "tfc"
}

variable "bu_stack_repo_suffix" {
  type        = string
  description = "Suffix for BU Stack repository names"
  default     = "bu-stack"
}

# NEW: HCP Terraform Stack configuration
variable "create_hcp_stacks" {
  type        = bool
  description = "Create HCP Terraform Stacks for each BU"
  default     = true
}

variable "platform_stack_project" {
  type        = string
  description = "HCP Terraform project name where platform stack resides"
  default     = "Platform_Team"
}
```

## New Outputs (Enhanced for publish_output)

```hcl
# Existing outputs (kept)
output "bu_admin_team_ids" { ... }
output "bu_control_project_ids" { ... }
output "consumer_project_ids" { ... }

# NEW: Enhanced for Stacks
output "bu_admin_tokens" {
  description = "Map of BU admin team tokens for authentication"
  value       = { for k, v in tfe_team_token.bu_admin : k => v.token }
  sensitive   = true
}

output "bu_project_ids_map" {
  description = "Simplified map of BU names to control project IDs for publish_output"
  value       = { for k, v in tfe_project.bu_control : k => v.id }
}

output "organization_name" {
  description = "TFC organization name for downstream consumption"
  value       = var.tfc_organization_name
}

# NEW: GitHub repository outputs
output "bu_stack_repo_urls" {
  description = "Map of BU names to their Stack repository URLs"
  value       = var.create_bu_repositories ? {
    for k, v in github_repository.bu_stack : k => v.html_url
  } : {}
}

output "bu_stack_repo_names" {
  description = "Map of BU names to repository names"
  value       = var.create_bu_repositories ? {
    for k, v in github_repository.bu_stack : k => v.name
  } : {}
}

output "bu_stack_clone_urls" {
  description = "Map of BU names to Git clone URLs"
  value       = var.create_bu_repositories ? {
    for k, v in github_repository.bu_stack : k => v.ssh_clone_url
  } : {}
}

# NEW: HCP Terraform Stack outputs
output "bu_stack_ids" {
  description = "Map of BU names to HCP Terraform Stack IDs"
  value       = var.create_hcp_stacks ? {
    for k, v in tfe_stack.bu_stack : k => v.id
  } : {}
}
```

## New File: github.tf

```hcl
# Create GitHub repositories for BU Stacks
resource "github_repository" "bu_stack" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  name        = "${var.bu_stack_repo_prefix}-${each.key}-${var.bu_stack_repo_suffix}"
  description = "${each.key} Business Unit Stack for workspace management in HCP Terraform"
  
  visibility = "private"
  
  # Use template repository if specified
  template {
    owner      = split("/", var.bu_stack_template_repo)[0]
    repository = split("/", var.bu_stack_template_repo)[1]
    include_all_branches = false
  }
  
  has_issues    = true
  has_wiki      = false
  has_projects  = false
  has_downloads = false
  
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = false
  delete_branch_on_merge = true
  
  auto_init = var.bu_stack_template_repo == "" ? true : false
  
  vulnerability_alerts = true
}

# Configure default branch protection
resource "github_branch_protection" "bu_stack_main" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository_id = github_repository.bu_stack[each.key].node_id
  pattern       = "main"
  
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }
  
  required_status_checks {
    strict   = true
    contexts = ["terraform-stacks-validate"]
  }
  
  enforce_admins = false
}

# Grant BU admin team access to their repository
resource "github_team_repository" "bu_admin_access" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  team_id    = github_team.bu_admin[each.key].id
  repository = github_repository.bu_stack[each.key].name
  permission = "admin"
}

# Create GitHub team for BU admins
resource "github_team" "bu_admin" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  name        = "${each.key}-admins"
  description = "${each.key} BU administrators with access to Stack repository"
  privacy     = "closed"
}

# Seed initial Stack configuration files
resource "github_repository_file" "readme" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "README.md"
  content             = templatefile("${path.module}/templates/bu-stack-readme.md.tpl", {
    bu_name           = each.key
    bu_display_name   = title(each.key)
    organization      = var.tfc_organization_name
    platform_project  = var.platform_stack_project
    github_org        = var.github_organization
    repo_name         = github_repository.bu_stack[each.key].name
  })
  commit_message      = "Initialize ${each.key} BU Stack"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed variables.tfcomponent.hcl
resource "github_repository_file" "variables" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "variables.tfcomponent.hcl"
  content             = templatefile("${path.module}/templates/variables.tfcomponent.hcl.tpl", {
    bu_name = each.key
  })
  commit_message      = "Add Stack variables configuration"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed providers.tfcomponent.hcl
resource "github_repository_file" "providers" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "providers.tfcomponent.hcl"
  content             = templatefile("${path.module}/templates/providers.tfcomponent.hcl.tpl", {
    bu_name           = each.key
    oidc_audience     = "${each.key}-team-*"
  })
  commit_message      = "Add Stack providers configuration"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed components.tfcomponent.hcl
resource "github_repository_file" "components" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "components.tfcomponent.hcl"
  content             = templatefile("${path.module}/templates/components.tfcomponent.hcl.tpl", {
    bu_name       = each.key
    organization  = var.tfc_organization_name
  })
  commit_message      = "Add Stack components configuration"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed outputs.tfcomponent.hcl
resource "github_repository_file" "outputs" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "outputs.tfcomponent.hcl"
  content             = file("${path.module}/templates/outputs.tfcomponent.hcl")
  commit_message      = "Add Stack outputs configuration"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed deployments.tfdeploy.hcl
resource "github_repository_file" "deployments" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "deployments.tfdeploy.hcl"
  content             = templatefile("${path.module}/templates/deployments.tfdeploy.hcl.tpl", {
    bu_name           = each.key
    organization      = var.tfc_organization_name
    platform_project  = var.platform_stack_project
    oidc_audience     = "${each.key}-team-*"
  })
  commit_message      = "Add Stack deployments configuration"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed example YAML config
resource "github_repository_file" "yaml_config" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "configs/${each.key}.yaml"
  content             = templatefile("${path.module}/templates/bu-config.yaml.tpl", {
    bu_name = each.key
  })
  commit_message      = "Add example workspace configuration"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}

# Seed GitHub Actions workflow
resource "github_repository_file" "github_actions" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = ".github/workflows/terraform-stacks.yml"
  content             = templatefile("${path.module}/templates/github-actions.yml.tpl", {
    bu_name = each.key
  })
  commit_message      = "Add CI/CD workflow"
  commit_author       = "Platform Team"
  commit_email        = "platform-team@cloudbrokeraz.com"
  overwrite_on_create = true
}
```

## New File: stacks.tf (HCP Terraform Stack Creation)

```hcl
# Create HCP Terraform Stacks for each BU
resource "tfe_stack" "bu_stack" {
  for_each = var.create_hcp_stacks ? local.tenant : {}

  name         = "${each.key}-bu-stack"
  project_id   = tfe_project.bu_control[each.key].id
  description  = "${each.key} Business Unit Stack for workspace management"
  
  vcs_repo {
    identifier         = "${var.github_organization}/${github_repository.bu_stack[each.key].name}"
    branch             = "main"
    oauth_token_id     = var.vcs_oauth_token_id
  }
}

# Variable needed in variables.tf
variable "vcs_oauth_token_id" {
  type        = string
  description = "OAuth token ID for VCS connection to GitHub"
  default     = ""
}
```

## Updated versions.tf

```hcl
terraform {
  required_version = ">= 1.13.5"
  
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60"
    }
    
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# NO provider blocks - configured by Stack
```

## Templates Directory

Create `templates/` directory with:

### templates/bu-stack-readme.md.tpl
```markdown
# ${bu_display_name} BU Stack

Welcome to the ${bu_display_name} Business Unit Stack for HCP Terraform!

This repository was automatically created by the Platform Team and contains everything you need to manage your team's workspaces.

## Getting Started

1. **Clone this repository**:
   ```bash
   git clone git@github.com:${github_org}/${repo_name}.git
   cd ${repo_name}
   ```

2. **Edit your workspace configuration**:
   - Open `configs/${bu_name}.yaml`
   - Add your workspace definitions

3. **Commit and push**:
   ```bash
   git add configs/${bu_name}.yaml
   git commit -m "Add workspace definitions"
   git push origin main
   ```

4. **HCP Terraform automatically deploys**:
   - Dev deployment: After push to main
   - Staging: Manual approval
   - Production: Manual approval

## Stack Structure

- `variables.tfcomponent.hcl` - Stack input variables
- `providers.tfcomponent.hcl` - Provider configurations (TFE, GitHub)
- `components.tfcomponent.hcl` - Component definitions (sources bu-onboarding module)
- `outputs.tfcomponent.hcl` - Stack outputs
- `deployments.tfdeploy.hcl` - Deployment definitions (dev, staging, prod)
- `configs/${bu_name}.yaml` - Your workspace configuration

## YAML Configuration Format

See example in `configs/${bu_name}.yaml`.

## Consuming Platform Stack Outputs

This Stack automatically consumes outputs from the Platform Stack:
- Organization name
- Your BU project ID
- Your BU admin team token

These are available via `upstream_input.platform_stack.*`

## Support

Contact the Platform Team: platform-team@cloudbrokeraz.com
```

### templates/variables.tfcomponent.hcl.tpl
```hcl
variable "organization" {
  type        = string
  description = "HCP Terraform organization name"
}

variable "bu_name" {
  type        = string
  description = "Business unit name"
  default     = "${bu_name}"
}

variable "project_id" {
  type        = string
  description = "BU control project ID from platform stack"
}

variable "admin_token" {
  type        = string
  description = "BU admin team token for authentication"
  sensitive   = true
  ephemeral   = true
}

variable "yaml_config_content" {
  type        = string
  description = "YAML configuration content for workspace definitions"
}

variable "oauth_token_id" {
  type        = string
  description = "OAuth token ID for VCS integration"
}

variable "github_org" {
  type        = string
  description = "GitHub organization name"
}
```

### templates/providers.tfcomponent.hcl.tpl
```hcl
required_providers {
  tfe = {
    source  = "hashicorp/tfe"
    version = "~> 0.60"
  }
  github = {
    source  = "integrations/github"
    version = "~> 6.0"
  }
}

# OIDC Authentication for TFE
provider "tfe" "${bu_name}" {
  config {
    hostname = "app.terraform.io"
    token    = var.identity_token_tfe
  }
}

# GitHub provider
provider "github" "${bu_name}" {
  config {
    owner = var.github_org
    token = var.github_token
  }
}
```

### templates/components.tfcomponent.hcl.tpl
```hcl
component "bu_control" {
  source  = "app.terraform.io/${organization}/bu-onboarding/tfe"
  version = "1.0.0"
  
  inputs = {
    organization       = var.organization
    bu_name            = var.bu_name
    project_id         = var.project_id
    admin_token        = var.admin_token
    yaml_config_content = var.yaml_config_content
    oauth_token_id     = var.oauth_token_id
    github_org         = var.github_org
  }
  
  providers = {
    tfe    = provider.tfe.${bu_name}
    github = provider.github.${bu_name}
  }
}
```

### templates/outputs.tfcomponent.hcl
```hcl
output "workspace_ids" {
  type        = map(string)
  description = "Map of workspace names to IDs"
  value       = component.bu_control.workspace_ids
}

output "workspace_names" {
  type        = list(string)
  description = "List of created workspace names"
  value       = component.bu_control.workspace_names
}

output "repository_urls" {
  type        = map(string)
  description = "Map of workspace repositories"
  value       = component.bu_control.repository_urls
}
```

### templates/deployments.tfdeploy.hcl.tpl
```hcl
# Upstream input from platform stack
upstream_input "platform_stack" {
  type   = "stack"
  source = "app.terraform.io/${organization}/${platform_project}/platform-stack"
}

# OIDC identity token
identity_token "tfe_${bu_name}" {
  audience = ["${oidc_audience}"]
}

# Store block for variable sets (optional)
store "varset" "${bu_name}_config" {
  name     = "${bu_name}_admin"
  category = "terraform"
}

locals {
  organization = upstream_input.platform_stack.organization_name
  project_id   = upstream_input.platform_stack.bu_project_ids_map["${bu_name}"]
  admin_token  = upstream_input.platform_stack.bu_admin_tokens["${bu_name}"]
}

# Development deployment
deployment "${bu_name}_dev" {
  inputs = {
    organization        = local.organization
    bu_name             = var.bu_name
    project_id          = local.project_id
    admin_token         = local.admin_token
    yaml_config_content = file("$${path.module}/configs/${bu_name}.yaml")
    oauth_token_id      = store.varset.${bu_name}_config.oauth_token_id
    github_org          = store.varset.${bu_name}_config.github_org
    identity_token_tfe  = identity_token.tfe_${bu_name}.jwt
  }
}

# Staging deployment
deployment "${bu_name}_staging" {
  inputs = {
    organization        = local.organization
    bu_name             = var.bu_name
    project_id          = local.project_id
    admin_token         = local.admin_token
    yaml_config_content = file("$${path.module}/configs/${bu_name}.yaml")
    oauth_token_id      = store.varset.${bu_name}_config.oauth_token_id
    github_org          = store.varset.${bu_name}_config.github_org
    identity_token_tfe  = identity_token.tfe_${bu_name}.jwt
  }
}

# Production deployment
deployment "${bu_name}_prod" {
  inputs = {
    organization        = local.organization
    bu_name             = var.bu_name
    project_id          = local.project_id
    admin_token         = local.admin_token
    yaml_config_content = file("$${path.module}/configs/${bu_name}.yaml")
    oauth_token_id      = store.varset.${bu_name}_config.oauth_token_id
    github_org          = store.varset.${bu_name}_config.github_org
    identity_token_tfe  = identity_token.tfe_${bu_name}.jwt
  }
}
```

### templates/bu-config.yaml.tpl
```yaml
bu: "${bu_name}"
description: "${bu_name} workspace configuration"

workspaces:
  - name: "${bu_name}-app-dev"
    description: "Development application workspace"
    terraform_version: "1.9.0"
    auto_apply: false
    vcs_repo:
      identifier: "your-org/your-app-repo"
      branch: "develop"
    tags:
      - dev
      - ${bu_name}
```

### templates/github-actions.yml.tpl
```yaml
name: Terraform Stacks CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    name: Validate Stack Configuration
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.13.5"
      
      - name: Terraform Stacks Validate
        run: terraform stacks validate
  
  plan:
    name: Plan Deployments
    needs: validate
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        deployment: [${bu_name}_dev, ${bu_name}_staging, ${bu_name}_prod]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.13.5"
      
      - name: Terraform Stacks Plan
        run: terraform stacks plan --deployment=$${{ matrix.deployment }}
        env:
          TF_TOKEN_app_terraform_io: $${{ secrets.TFC_TOKEN }}
```

## Migration Path

1. **Publish current modules to PMR** (as `platform-onboarding` and `bu-onboarding`)
2. **Create platform stack repository** with refactored module
3. **Test repository creation** with single BU
4. **Verify BU Stack repo** has all necessary files
5. **Deploy remaining BUs**
6. **Notify BU teams** to clone and customize

## Benefits of This Approach

✅ **Complete Automation** - BU repos created automatically
✅ **Turnkey Solution** - BU teams get working Stack immediately
✅ **Consistent Structure** - All BU Stacks follow same pattern
✅ **Pre-configured** - OIDC, upstream inputs, deployments ready
✅ **Self-Service** - BU teams just edit YAML and push
✅ **Platform Control** - Platform team manages template and creation

## Next Steps

1. Approve this refactoring approach
2. I'll generate all template files
3. I'll create the refactored module
4. I'll create the platform Stack configuration
5. We'll test with one BU first
