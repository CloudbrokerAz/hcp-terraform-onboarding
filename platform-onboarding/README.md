# Platform Onboarding Module

Terraform module for onboarding business units to HCP Terraform with **automated GitHub repository creation** for BU-owned Terraform Stacks.

## Overview

This module is designed for **platform teams** to provision HCP Terraform infrastructure for business units, including:

- ✅ **BU Control Projects** - Dedicated projects per business unit
- ✅ **Admin Teams & Tokens** - Team-based access control with API tokens
- ✅ **Control Workspaces** - Workspace management infrastructure
- ✅ **Variable Sets** - Centralized configuration management
- ✅ **Consumer Projects** - Application-specific projects from YAML configs
- ✅ **Automated GitHub Repository Creation** - Creates turnkey BU Stack repositories with seeded configurations
- ✅ **GitHub Teams & Access** - BU admin teams with repository permissions
- ✅ **Branch Protection** - Enforces code review and CI checks

## Features

### Core Infrastructure
- Creates BU-specific projects with naming convention: `BU_{bu_name}`
- Creates admin teams: `{bu_name}_admin`
- Generates team tokens for BU authentication
- Creates control workspaces: `{bu_name}_workspace_control`
- Provisions variable sets with project IDs and tokens

### Consumer Projects (YAML-Driven)
- Reads `config/*.yaml` files for project definitions
- Creates consumer projects: `BU_{bu}__{project_name}`
- Grants BU admin teams access to all projects
- Creates project-specific variable sets (optional)
- Processes project-level variables from YAML

### GitHub Integration (NEW!)
- **Automatically creates GitHub repositories** for each BU's Terraform Stack
- **Seeds 8+ configuration files** in each repository:
  - `README.md` - Complete BU-specific documentation
  - `variables.tfcomponent.hcl` - Stack input variables
  - `providers.tfcomponent.hcl` - TFE provider with OIDC
  - `components.tfcomponent.hcl` - Component sourcing bu-onboarding module
  - `outputs.tfcomponent.hcl` - Stack outputs
  - `deployments.tfdeploy.hcl` - Dev/staging/prod deployments with upstream inputs
  - `configs/{bu_name}.yaml` - Example workspace configuration
  - `.github/workflows/terraform-stacks.yml` - CI/CD workflow
- **Creates GitHub teams** for BU admins
- **Grants admin access** to BU repositories
- **Enables branch protection** on main branch (optional)

### Enhanced Outputs for Stacks
- Structured outputs optimized for `publish_output` in Terraform Stacks
- Maps of BU project IDs, tokens, workspaces, GitHub repos
- Comprehensive `bu_infrastructure` output for downstream consumption

## Architecture

This module is designed for the **Terraform Stacks linked stacks pattern**:

```
┌─────────────────────────────────────────────────────────────┐
│ Platform Stack (Platform_Team project)                      │
│                                                              │
│  Component: platform-onboarding (this module)               │
│  ├─ Creates: BU projects, teams, tokens                     │
│  ├─ Creates: GitHub repos with seeded Stack configs         │
│  └─ Publishes: bu_infrastructure output                     │
│                                                              │
│  Deployments:                                               │
│    ├─ finance (publish_output)                              │
│    ├─ engineering (publish_output)                          │
│    └─ sales (publish_output)                                │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    (publish_output → upstream_input)
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ BU Stack (tfc-finance-bu-stack repo, BU_finance project)    │
│                                                              │
│  Component: bu-onboarding                                   │
│  ├─ Upstream: bu_project_id, bu_admin_token                 │
│  ├─ Reads: configs/finance.yaml                             │
│  └─ Creates: Workspaces from YAML                           │
│                                                              │
│  Deployments:                                               │
│    ├─ dev (BU_finance project)                              │
│    ├─ staging (BU_finance project)                          │
│    └─ production (BU_finance project)                       │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.5 |
| tfe | ~> 0.60 |
| github | ~> 6.0 |

**IMPORTANT**: This module does NOT include provider blocks. When using with Terraform Stacks, configure providers in your Stack's `providers.tfcomponent.hcl` file.

## Usage

### Basic Example (Without GitHub Integration)

```hcl
module "platform_onboarding" {
  source = "app.terraform.io/cloudbrokeraz/platform-onboarding/tfe"
  
  tfc_organization_name = "cloudbrokeraz"
  
  # Optional: Filter to single BU
  # business_unit = "finance"
  
  # Disable GitHub features
  create_bu_repositories = false
}
```

### Complete Example (With GitHub Integration)

```hcl
module "platform_onboarding" {
  source = "app.terraform.io/cloudbrokeraz/platform-onboarding/tfe"
  
  # TFC Organization
  tfc_organization_name = "cloudbrokeraz"
  
  # GitHub Configuration
  create_bu_repositories = true
  github_organization    = "CloudbrokerAz"
  bu_stack_repo_prefix   = "tfc"
  bu_stack_repo_suffix   = "bu-stack"
  
  # Optional: Use template repository
  # bu_stack_template_repo = "CloudbrokerAz/tfc-bu-stack-template"
  
  # HCP Terraform Stacks integration (optional)
  create_hcp_stacks      = false  # Managed separately via Stack deployment
  vcs_oauth_token_id     = ""     # Required if create_hcp_stacks = true
  platform_stack_project = "Platform_Team"
  
  # GitHub Settings
  github_team_privacy      = "closed"
  enable_branch_protection = true
  
  # Commit Author
  commit_author_name  = "Platform Team"
  commit_author_email = "platform-team@cloudbrokeraz.com"
}
```

### YAML Configuration Example

Create `config/finance.yaml`:

```yaml
business_unit: finance

projects:
  - name: payment-gateway
    description: Payment processing infrastructure
    
    var_sets:
      variables:
        - key: environment
          value: production
          category: terraform
    
    workspaces:
      - name: payment-gateway-api
        description: Payment API infrastructure
        terraform_version: "1.9.0"
        working_directory: "terraform/"
        vcs_repo:
          identifier: "CloudbrokerAz/payment-gateway"
          branch: "main"
```

## Providers

Providers are **NOT** configured in this module. Configure them in your Terraform Stack:

```hcl
# In your Stack's providers.tfcomponent.hcl

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

provider "tfe" "this" {
  config {
    hostname = "app.terraform.io"
    token    = var.tfe_identity_token  # OIDC token
  }
}

provider "github" "this" {
  config {
    owner = "CloudbrokerAz"
    token = var.github_token
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tfc_organization_name | HCP Terraform organization name | `string` | n/a | yes |
| business_unit | Filter to single business unit (null = all BUs) | `string` | `null` | no |
| create_bu_repositories | Create GitHub repositories for BU Stacks | `bool` | `true` | no |
| github_organization | GitHub organization name | `string` | `""` | no |
| bu_stack_template_repo | Template repo (format: org/repo) | `string` | `""` | no |
| bu_stack_repo_prefix | Repository name prefix | `string` | `"tfc"` | no |
| bu_stack_repo_suffix | Repository name suffix | `string` | `"bu-stack"` | no |
| create_hcp_stacks | Create HCP Terraform Stacks | `bool` | `false` | no |
| vcs_oauth_token_id | VCS OAuth token ID | `string` | `""` | no |
| platform_stack_project | Platform stack project name | `string` | `"Platform_Team"` | no |
| github_team_privacy | GitHub team privacy (closed/secret) | `string` | `"closed"` | no |
| enable_branch_protection | Enable branch protection on main | `bool` | `true` | no |
| commit_author_name | Git commit author name | `string` | `"Platform Team"` | no |
| commit_author_email | Git commit author email | `string` | `"platform-team@cloudbrokeraz.com"` | no |

## Outputs

### Core Outputs
| Name | Description |
|------|-------------|
| organization_name | HCP Terraform organization name |
| business_units | List of business units |
| deployment_summary | Resource creation summary |

### BU Infrastructure Outputs (for publish_output)
| Name | Description |
|------|-------------|
| bu_project_ids_map | Map of BU names to project IDs |
| bu_admin_tokens | Map of BU names to admin tokens (sensitive) |
| bu_infrastructure | Complete structured output per BU |

### GitHub Outputs
| Name | Description |
|------|-------------|
| bu_stack_repo_names | Map of BU names to repo names |
| bu_stack_repo_urls | Map of BU names to repo URLs |
| bu_stack_clone_urls | Map of BU names to SSH clone URLs |
| bu_github_team_ids | Map of BU names to GitHub team IDs |

## GitHub Repository Naming

Repositories are created with the pattern:
```
{bu_stack_repo_prefix}-{bu_name}-{bu_stack_repo_suffix}
```

**Examples:**
- `tfc-finance-bu-stack`
- `tfc-engineering-bu-stack`
- `tfc-sales-bu-stack`

## Template Files

The module seeds 8 files in each BU repository:

1. **README.md** - BU-specific documentation
2. **variables.tfcomponent.hcl** - Stack variables
3. **providers.tfcomponent.hcl** - TFE provider with OIDC
4. **components.tfcomponent.hcl** - Component sourcing bu-onboarding
5. **outputs.tfcomponent.hcl** - Stack outputs
6. **deployments.tfdeploy.hcl** - Dev/staging/prod with upstream_input
7. **configs/{bu_name}.yaml** - Example workspace config
8. **.github/workflows/terraform-stacks.yml** - CI/CD workflow

## Publishing to Private Module Registry

1. **Tag the repository**:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. **Configure module in PMR**:
   - Navigate to HCP Terraform → Registry → Publish
   - Select GitHub repository
   - Choose `platform-onboarding` as module name
   - Set provider: `tfe`

3. **Reference in Stacks**:
   ```hcl
   component "platform_onboarding" {
     source  = "app.terraform.io/cloudbrokeraz/platform-onboarding/tfe"
     version = "~> 1.0"
     
     inputs = {
       tfc_organization_name = var.tfc_organization_name
       # ...
     }
   }
   ```

## Module Dependencies

### YAML Configuration Files
Place YAML files in `config/` directory at the root of your Stack repository:

```
platform-stack/
├── config/
│   ├── finance.yaml
│   ├── engineering.yaml
│   └── sales.yaml
├── variables.tfcomponent.hcl
├── providers.tfcomponent.hcl
└── components.tfcomponent.hcl
```

### GitHub OAuth Token
Required for GitHub provider authentication:
- Personal Access Token (PAT) with `repo` and `admin:org` scopes
- Pass via variable or environment variable in Stack deployment

### HCP Terraform Permissions
Required permissions:
- **Organization**: Manage projects
- **Organization**: Manage teams
- **Organization**: Manage workspaces
- **Organization**: Manage variable sets

## Troubleshooting

### "Repository already exists"
**Cause**: GitHub repository with same name exists  
**Fix**: Change `bu_stack_repo_prefix` or `bu_stack_repo_suffix`, or delete existing repo

### "Insufficient permissions to create team"
**Cause**: GitHub token missing `admin:org` scope  
**Fix**: Regenerate token with correct scopes

### "Failed to read YAML file"
**Cause**: YAML syntax error in config file  
**Fix**: Validate YAML with `yamllint configs/*.yaml`

### "Variable set not found"
**Cause**: Project-specific variable set expects variables but none defined  
**Fix**: Ensure YAML has `var_sets.variables` list if using var_sets

## Related Resources

- **bu-onboarding Module**: Consumes outputs from this module
- **Platform Stack**: Stacks configuration using this module
- **BU Stack Template**: Template for BU-owned Stacks

## License

MIT License

## Support

Platform Team - `platform-team@cloudbrokeraz.com`

---

**Module Version**: 1.0.0  
**Terraform Stacks**: v1.13.5+  
**Last Updated**: 2024
