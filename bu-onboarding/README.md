# BU Onboarding Module

Terraform module for business units to provision and manage HCP Terraform workspaces from YAML configuration files. Designed for use with **Terraform Stacks** and consumes upstream outputs from the platform-onboarding module.

## Overview

This module enables **business unit teams** to manage their own HCP Terraform workspaces through a **YAML-driven declarative approach**. Place YAML files in the `config/` directory to define workspaces, and this module will provision them automatically.

## Features

- ✅ **YAML-Driven Configuration** - Define workspaces in simple YAML files
- ✅ **VCS Integration** - Automatic GitHub/GitLab/Bitbucket connection
- ✅ **Variable Management** - Workspace variables and variable sets
- ✅ **Multi-Environment Support** - Tag workspaces by environment (dev/staging/prod)
- ✅ **Agent Execution** - Support for self-hosted Terraform agents
- ✅ **Remote State Sharing** - Optional remote state access between workspaces
- ✅ **Drift Detection** - Optional workspace assessments
- ✅ **Auto-Apply** - Configurable automatic apply on successful plans
- ✅ **Upstream Integration** - Consumes platform stack outputs (project ID, tokens)

## Architecture

This module is designed for the **Terraform Stacks linked stacks pattern**:

```
Platform Stack (platform-onboarding)
  ↓ publish_output
  ↓ (bu_project_id, bu_admin_token)
  ↓ upstream_input
BU Stack (bu-onboarding) ← This Module
  ↓
  └─ Creates: Workspaces from config/*.yaml
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.5 |
| tfe | ~> 0.60 |

**IMPORTANT**: This module does NOT include provider blocks. Configure providers in your Terraform Stack's `providers.tfcomponent.hcl` file.

## Usage

### Basic Example

```hcl
component "bu_onboarding" {
  source = "app.terraform.io/cloudbrokeraz/bu-onboarding/tfe"
  
  inputs = {
    # From platform stack (via upstream_input)
    tfc_organization_name = var.tfc_organization_name
    bu_project_id         = var.bu_project_id
    
    # VCS integration
    vcs_oauth_token_id = var.vcs_oauth_token_id
    
    # Environment tagging
    environment = var.environment  # dev, staging, production
    
    # Optional: Filter to specific business unit
    business_unit = var.business_unit
  }
  
  providers = {
    tfe = provider.tfe.this
  }
}
```

### Complete Example with Feature Flags

```hcl
component "bu_onboarding" {
  source  = "app.terraform.io/cloudbrokeraz/bu-onboarding/tfe"
  version = "~> 1.0"
  
  inputs = {
    # Upstream from platform stack
    tfc_organization_name = var.tfc_organization_name
    bu_project_id         = var.bu_project_id
    
    # VCS integration
    vcs_oauth_token_id = var.vcs_oauth_token_id
    
    # Configuration
    business_unit = "finance"
    environment   = "production"
    
    # Feature flags
    enable_assessments           = true   # Enable drift detection
    queue_all_runs               = false  # Don't queue runs on creation
    enable_remote_state_sharing  = true   # Enable remote state between workspaces
  }
  
  providers = {
    tfe = provider.tfe.this
  }
}
```

## YAML Configuration

### Directory Structure

Place YAML files in the `config/` directory:

```
bu-stack/
├── configs/
│   ├── finance.yaml        # Finance BU workspaces
│   ├── web-app.yaml        # Web application workspaces
│   └── api-service.yaml    # API service workspaces
├── variables.tfcomponent.hcl
├── components.tfcomponent.hcl
└── deployments.tfdeploy.hcl
```

### YAML Schema

```yaml
business_unit: finance              # Business unit name (for filtering)
workspace_name: finance-web-app     # REQUIRED: Unique workspace name
project_name: web-applications      # Project name (deprecated - uses bu_project_id)
workspace_description: "Frontend infrastructure for finance web app"
workspace_terraform_version: "1.9.0"

# Execution settings
execution_mode: remote              # remote, local, or agent
workspace_agents: false             # Use self-hosted agents
agent_pool_name: null               # Agent pool name (if workspace_agents=true)
workspace_auto_apply: false         # Auto-apply on successful plan
queue_all_runs: false               # Queue all runs on creation
assessments_enabled: false          # Enable drift detection

# File triggers
file_triggers_enabled: true         # Enable file-based triggers
workspace_vcs_directory: "terraform/frontend"  # Working directory
trigger_prefixes:                   # File paths that trigger runs
  - "terraform/frontend/"
trigger_patterns:                   # File patterns (alternative to prefixes)
  - "**/*.tf"

# VCS repository
vcs_repo:
  identifier: "CloudbrokerAz/web-app"  # GitHub repo (org/repo)
  branch: main                         # Branch name

# Workspace tags
workspace_tags:
  - "app:web"
  - "tier:frontend"

# Workspace variables
variables:
  region:
    value: us-east-1
    category: terraform           # terraform or env
    description: "AWS region"
    hcl: false                    # Is HCL value
    sensitive: false              # Mark as sensitive
  
  instance_count:
    value: "3"
    category: terraform
    hcl: false
    sensitive: false
  
  db_password:
    value: "secret123"
    category: env
    sensitive: true

# Variable sets (optional)
create_variable_set: true
var_sets:
  - variable_set_name: finance-web-app-config
    variable_set_description: "Configuration for finance web app"
    global: false                 # Apply to all workspaces
    variables:
      app_name:
        value: finance-web-app
        category: terraform
        hcl: false
        sensitive: false
      
      environment:
        value: production
        category: terraform
        hcl: false
        sensitive: false

# Remote state (optional)
remote_state: true
remote_state_consumers:
  - "finance-api-service"         # Workspace names that can access state
```

### Minimal YAML Example

```yaml
business_unit: finance
workspace_name: finance-simple-app
workspace_description: "Simple finance application"
workspace_terraform_version: "1.9.0"

vcs_repo:
  identifier: "CloudbrokerAz/simple-app"
  branch: main
```

### Complete YAML Example

```yaml
business_unit: finance
workspace_name: finance-payment-gateway
workspace_description: "Payment processing infrastructure"
workspace_terraform_version: "1.9.0"
execution_mode: remote
workspace_auto_apply: false
assessments_enabled: true
queue_all_runs: false

file_triggers_enabled: true
workspace_vcs_directory: "terraform/"
trigger_prefixes:
  - "terraform/"
  - "modules/"

vcs_repo:
  identifier: "CloudbrokerAz/payment-gateway"
  branch: main

workspace_tags:
  - "app:payment"
  - "tier:backend"
  - "compliance:pci-dss"

variables:
  region:
    value: us-east-1
    category: terraform
    description: "Primary AWS region"
    hcl: false
    sensitive: false
  
  payment_provider_api_key:
    value: "sk_live_xxxxxxxxx"
    category: env
    description: "Payment provider API key"
    hcl: false
    sensitive: true
  
  allowed_ips:
    value: '["10.0.0.0/8", "172.16.0.0/12"]'
    category: terraform
    description: "Allowed IP ranges"
    hcl: true
    sensitive: false

create_variable_set: true
var_sets:
  - variable_set_name: payment-gateway-config
    variable_set_description: "Payment gateway configuration"
    global: false
    variables:
      gateway_url:
        value: "https://api.payment.cloudbrokeraz.com"
        category: terraform
        hcl: false
        sensitive: false
      
      webhook_secret:
        value: "whsec_xxxxxxxxx"
        category: env
        hcl: false
        sensitive: true

remote_state: true
remote_state_consumers:
  - "finance-api-service"
  - "finance-reporting"
```

## Providers

Providers are **NOT** configured in this module. Configure them in your Stack:

```hcl
# In your Stack's providers.tfcomponent.hcl

required_providers {
  tfe = {
    source  = "hashicorp/tfe"
    version = "~> 0.60"
  }
}

provider "tfe" "this" {
  config {
    hostname = "app.terraform.io"
    token    = var.tfe_identity_token  # OIDC token
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tfc_organization_name | HCP Terraform organization name | `string` | n/a | yes |
| bu_project_id | BU control project ID from platform stack | `string` | n/a | yes |
| vcs_oauth_token_id | OAuth token ID for VCS connection | `string` | n/a | yes |
| business_unit | Business unit name filter | `string` | `null` | no |
| environment | Environment name (dev/staging/production) | `string` | `"dev"` | no |
| enable_assessments | Enable drift detection | `bool` | `false` | no |
| queue_all_runs | Queue runs on workspace creation | `bool` | `false` | no |
| enable_remote_state_sharing | Enable remote state sharing | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| workspace_ids_map | Map of workspace names to IDs |
| workspace_names | List of workspace names |
| workspace_urls | Map of workspace URLs |
| variable_set_ids_map | Map of variable set IDs |
| deployment_summary | Summary of created resources |
| workspaces_with_vcs | Workspaces with VCS configured |
| workspaces_with_auto_apply | Workspaces with auto-apply enabled |

## Advanced Features

### Agent Execution

```yaml
workspace_name: finance-secure-app
execution_mode: agent
workspace_agents: true
agent_pool_name: finance-private-pool
```

### Remote State Sharing

Enable in module:
```hcl
inputs = {
  enable_remote_state_sharing = true
}
```

Configure in YAML:
```yaml
workspace_name: finance-database
remote_state: true
remote_state_consumers:
  - "finance-api-service"
  - "finance-web-app"
```

### Variable Sets

Create variable sets that can be shared across workspaces:

```yaml
create_variable_set: true
var_sets:
  - variable_set_name: shared-aws-config
    variable_set_description: "Shared AWS configuration"
    global: false
    variables:
      aws_region:
        value: us-east-1
        category: terraform
```

## Workflow

1. **Create YAML file** in `configs/` directory
2. **Commit and push** to main branch
3. **HCP Terraform triggers** Stack plan automatically
4. **Review plan** in HCP Terraform UI
5. **Apply** to create workspaces

## Migration from bu-control-workspace

This module replaces the original `bu-control-workspace` with these changes:

**Removed**:
- ❌ GitHub repository creation (moved to platform-onboarding)
- ❌ External module dependencies (inlined)
- ❌ Provider blocks (Stacks requirement)
- ❌ `create_project` support (project provided by platform stack)

**Added**:
- ✅ Upstream input consumption (`bu_project_id`)
- ✅ Environment tagging
- ✅ Business unit filtering
- ✅ Simplified variable set creation
- ✅ Enhanced outputs for Stacks

**YAML Changes**:
- `project_name` → Now uses `bu_project_id` from upstream
- `create_repo` → Removed (GitHub managed by platform stack)
- `business_unit` → Now used for filtering

## Publishing to Private Module Registry

1. **Tag the repository**:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. **Configure in PMR**:
   - Navigate to HCP Terraform → Registry → Publish
   - Select repository
   - Module name: `bu-onboarding`
   - Provider: `tfe`

3. **Reference in Stacks**:
   ```hcl
   component "bu_onboarding" {
     source  = "app.terraform.io/cloudbrokeraz/bu-onboarding/tfe"
     version = "~> 1.0"
   }
   ```

## Troubleshooting

### "Workspace already exists"
**Cause**: Workspace name collision  
**Fix**: Ensure `workspace_name` is unique across organization

### "Project not found"
**Cause**: Invalid `bu_project_id`  
**Fix**: Verify project ID from platform stack outputs

### "OAuth token not found"
**Cause**: Invalid `vcs_oauth_token_id`  
**Fix**: Check OAuth token ID in HCP Terraform settings

### "Agent pool not found"
**Cause**: Invalid `agent_pool_name`  
**Fix**: Verify agent pool exists in organization

### "Failed to parse YAML"
**Cause**: YAML syntax error  
**Fix**: Validate with `yamllint configs/*.yaml`

## Examples

See the `examples/` directory for:
- **basic/** - Minimal workspace configuration
- **complete/** - Full-featured with all options

## Related Resources

- **platform-onboarding Module**: Creates BU infrastructure (upstream)
- **Platform Stack**: Sources platform-onboarding
- **BU Stack**: Sources this module (bu-onboarding)

## License

MIT License

## Support

Platform Team - `platform-team@cloudbrokeraz.com`

---

**Module Version**: 1.0.0  
**Terraform Stacks**: v1.13.5+  
**Last Updated**: November 2024
