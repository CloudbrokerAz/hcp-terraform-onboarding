# Terraform Stacks Architecture Assessment & Design

## Executive Summary

This document provides a comprehensive assessment of converting the current workspace-based HCP Terraform onboarding pattern to **Terraform Stacks with Linked Stacks architecture**.

### Key Findings

✅ **Repository Split Required**: YES - Linked Stacks require 1:1 Stack-to-repository relationship
✅ **Fundamental Architecture Valid**: Platform team → BU team delegation pattern aligns perfectly with Stacks
✅ **Publish/Upstream Pattern**: Platform stack publishes outputs, BU stacks consume via upstream_input
✅ **Module Compatibility**: Both modules need minor refactoring (remove provider blocks)

---

## Your Questions Answered

### 1. Fundamental Flow Assessment

**Your proposed flow is CORRECT** ✅

```
Platform Team Stack (Repository 1)
         ↓ publish_output
BU Team Stacks (Repository 2)
         ↓ upstream_input
    Workspace Creation
```

**Flow Details:**

**Platform Stack Responsibilities:**
- Create BU admin teams (`tfe_team`)
- Provision BU control projects (`tfe_project`)
- Generate team tokens (`tfe_team_token`)
- Create variable sets with tokens (`tfe_variable_set`)
- **Publish outputs**: BU project IDs, team tokens, org name

**BU Stack Responsibilities:**
- **Consume upstream inputs**: Project IDs and tokens from platform stack
- YAML-driven workspace provisioning
- GitHub repository creation
- VCS connections
- Variable set associations
- Team access assignments

### 2. Published Outputs Pattern

**Platform Stack Publishes:**

```hcl
# In platform-stack/outputs.tfcomponent.hcl
output "bu_project_ids" {
  type        = map(string)
  description = "Map of BU names to project IDs"
  value       = {
    for k, v in component.tenant_config.bu_projects : k => v
  }
}

output "bu_admin_tokens" {
  type        = map(string)
  description = "Map of BU names to admin team tokens"
  sensitive   = true
  value       = {
    for k, v in component.tenant_config.bu_tokens : k => v
  }
}

output "organization_name" {
  type        = string
  description = "TFC organization name"
  value       = var.tfc_organization_name
}

# In platform-stack/deployments.tfdeploy.hcl
publish_output "bu_project_ids" {
  value = deployment.platform.bu_project_ids
}

publish_output "bu_admin_tokens" {
  value = deployment.platform.bu_admin_tokens
}

publish_output "organization_name" {
  value = deployment.platform.organization_name
}
```

**BU Stack Consumes:**

```hcl
# In bu-stack/deployments.tfdeploy.hcl
upstream_input "platform_stack" {
  type   = "stack"
  source = "app.terraform.io/YOUR_ORG/platform-project/platform-stack"
}

deployment "finance" {
  inputs = {
    bu_name         = "finance"
    organization    = upstream_input.platform_stack.organization_name
    project_id      = upstream_input.platform_stack.bu_project_ids["finance"]
    admin_token     = upstream_input.platform_stack.bu_admin_tokens["finance"]
    yaml_config     = file("${path.module}/configs/finance.yaml")
  }
}
```

### 3. Approach Assessment

**Your instincts are CORRECT**:

1. ✅ **Platform Stack First** - Must be deployed before BU stacks can reference it
2. ✅ **Linked Stacks Pattern** - Proper use of publish_output → upstream_input
3. ✅ **Ownership Model** - Platform team owns platform stack, BU teams own their deployments
4. ✅ **Number of Workspaces** - BU teams control their deployment inputs

**Additional Considerations:**

- **Deployment Ordering**: Platform stack must complete before BU stacks can plan
- **State Isolation**: Each deployment has isolated state (good for multi-tenancy)
- **Variable Flow**: Use `store` blocks for shared variable sets (Premium feature)
- **OIDC Authentication**: Both stacks need identity_token blocks for TFE provider

### 4. Repository Split - REQUIRED

**Confirmation: YES, you MUST split repositories** ✅

**Current Structure (Monorepo):**
```
hcp-terraform-onboarding/
├── tenant-config-project/    # Module
├── bu-control-workspace/     # Module
└── examples/
```

**Required Structure (Separate Repos):**

**Repository 1: platform-stack**
```
platform-stack/
├── variables.tfcomponent.hcl
├── providers.tfcomponent.hcl
├── components.tfcomponent.hcl       # Sources tenant-config module from PMR
├── outputs.tfcomponent.hcl          # Stack outputs
├── deployments.tfdeploy.hcl         # Deployment + publish_output blocks
├── .terraform.lock.hcl
├── examples/
│   ├── basic/
│   └── complete/
└── README.md
```

**Repository 2: bu-stack**
```
bu-stack/
├── variables.tfcomponent.hcl
├── providers.tfcomponent.hcl
├── components.tfcomponent.hcl       # Sources bu-control module from PMR
├── outputs.tfcomponent.hcl
├── deployments.tfdeploy.hcl         # upstream_input + deployment blocks
├── .terraform.lock.hcl
├── configs/
│   ├── finance.yaml
│   ├── engineering.yaml
│   └── sales.yaml
├── examples/
│   ├── basic/
│   └── complete/
└── README.md
```

**Why Separate Repositories?**

Per Stacks documentation:
> "Linked Stacks require each Stack to be in its own repository with a 1:1 relationship to HCP Terraform Stack resources."

**Benefits:**
- Clear ownership boundaries (Platform team vs BU teams)
- Independent deployment lifecycle
- Granular access control (who can modify platform vs BU configurations)
- Separate CI/CD pipelines
- Isolated change management

### 5. Module References to PMR

**Both modules will be published to PMR:**

**Platform Stack Component:**
```hcl
component "tenant_config" {
  source  = "app.terraform.io/YOUR_ORG/tenant-config/tfe"
  version = "1.0.0"
  
  inputs = {
    tfc_organization_name = var.tfc_organization_name
    business_units        = var.business_units
  }
  
  providers = {
    tfe = provider.tfe.platform
  }
}
```

**BU Stack Component:**
```hcl
component "bu_control" {
  source  = "app.terraform.io/YOUR_ORG/bu-control/tfe"
  version = "1.0.0"
  
  inputs = {
    organization   = var.organization
    bu_name        = var.bu_name
    project_id     = var.project_id
    yaml_config    = var.yaml_config
    oauth_token_id = var.oauth_token_id
  }
  
  providers = {
    tfe    = provider.tfe.bu
    github = provider.github.bu
  }
}
```

**PMR Publishing Commands:**

```bash
# Publish tenant-config module
cd tenant-config-project/
git tag -a tenant-v1.0.0 -m "Release tenant-config v1.0.0"
git push origin tenant-v1.0.0

# Publish bu-control module
cd bu-control-workspace/
git tag -a bu-v1.0.0 -m "Release bu-control v1.0.0"
git push origin bu-v1.0.0
```

---

## Architecture Diagrams

### Linked Stacks Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│ Repository 1: platform-stack                                         │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Component: tenant_config                                    │    │
│  │ Source: app.terraform.io/ORG/tenant-config/tfe             │    │
│  │                                                             │    │
│  │ Creates:                                                    │    │
│  │  - BU admin teams                                          │    │
│  │  - BU control projects                                     │    │
│  │  - Team tokens                                             │    │
│  │  - Variable sets                                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          ▼                                           │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Stack Outputs (outputs.tfcomponent.hcl)                    │    │
│  │  - bu_project_ids: map(string)                             │    │
│  │  - bu_admin_tokens: map(string) [sensitive]                │    │
│  │  - organization_name: string                               │    │
│  └────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          ▼                                           │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Publish Outputs (deployments.tfdeploy.hcl)                 │    │
│  │  publish_output "bu_project_ids" { ... }                   │    │
│  │  publish_output "bu_admin_tokens" { ... }                  │    │
│  │  publish_output "organization_name" { ... }                │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               │ HCP Terraform Stack Outputs
                               │ Available to linked stacks
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Repository 2: bu-stack                                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Upstream Input (deployments.tfdeploy.hcl)                  │    │
│  │ upstream_input "platform_stack" {                          │    │
│  │   type   = "stack"                                         │    │
│  │   source = "app.terraform.io/ORG/PROJECT/platform-stack"   │    │
│  │ }                                                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          ▼                                           │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Deployment: finance                                         │    │
│  │ inputs = {                                                  │    │
│  │   bu_name      = "finance"                                 │    │
│  │   project_id   = upstream_input.platform_stack             │    │
│  │                    .bu_project_ids["finance"]              │    │
│  │   admin_token  = upstream_input.platform_stack             │    │
│  │                    .bu_admin_tokens["finance"]             │    │
│  │   organization = upstream_input.platform_stack             │    │
│  │                    .organization_name                      │    │
│  │ }                                                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          ▼                                           │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ Component: bu_control                                       │    │
│  │ Source: app.terraform.io/ORG/bu-control/tfe                │    │
│  │                                                             │    │
│  │ Creates:                                                    │    │
│  │  - YAML-driven workspaces                                  │    │
│  │  - GitHub repositories                                     │    │
│  │  - VCS connections                                         │    │
│  │  - Variable sets                                           │    │
│  │  - Team access                                             │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Deployment Sequence

```
┌─────────────────────────────────────────────────────────────────────┐
│ Step 1: Deploy Platform Stack                                       │
│                                                                      │
│  $ cd platform-stack/                                                │
│  $ terraform stacks providers-lock                                   │
│  $ terraform stacks validate                                         │
│  $ terraform stacks plan --deployment=platform                       │
│  $ terraform stacks apply --deployment=platform                      │
│                                                                      │
│  Result:                                                             │
│   - Finance admin team created                                      │
│   - Finance control project created                                 │
│   - Finance admin token generated                                   │
│   - Variable set with token created                                 │
│   - Outputs published and available                                 │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 2: Deploy BU Stack (Finance)                                   │
│                                                                      │
│  $ cd bu-stack/                                                      │
│  $ terraform stacks providers-lock                                   │
│  $ terraform stacks validate                                         │
│  $ terraform stacks plan --deployment=finance                        │
│  $ terraform stacks apply --deployment=finance                       │
│                                                                      │
│  Result:                                                             │
│   - Consumes finance project ID from platform stack                 │
│   - Uses finance admin token for authentication                     │
│   - Reads finance.yaml configuration                                │
│   - Creates workspaces in finance control project                   │
│   - Sets up GitHub repos and VCS connections                        │
└─────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Step 3: Finance Team Self-Service                                   │
│                                                                      │
│  Finance team can now:                                               │
│   1. Update finance.yaml with new workspace definitions             │
│   2. Commit to bu-stack repository                                   │
│   3. Automatic plan/apply (VCS-driven workflow)                     │
│   4. New workspaces created within their control project            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Module Refactoring Requirements

### Both Modules Must:

1. **Remove Provider Blocks**: Stacks components cannot contain provider configurations
2. **Expose Comprehensive Outputs**: All important resource attributes for Stack consumption
3. **Accept Granular Inputs**: Variables for all configurable aspects
4. **Support PMR Publishing**: Standard module structure with examples and tests

### tenant-config-project Module Changes

**Current Issues:**
- ✅ Already has no provider block (good!)
- ❌ Outputs may need enhancement for publish_output pattern

**Required Changes:**

```hcl
# tenant-config-project/outputs.tf
output "bu_projects" {
  description = "Map of BU names to project details"
  value = {
    for k, v in tfe_project.bu_control : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "bu_admin_teams" {
  description = "Map of BU names to admin team details"
  value = {
    for k, v in tfe_team.bu_admin : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "bu_admin_tokens" {
  description = "Map of BU names to admin team tokens"
  sensitive   = true
  value = {
    for k, v in tfe_team_token.bu_admin : k => v.token
  }
}

output "bu_control_workspaces" {
  description = "Map of BU names to control workspace IDs"
  value = {
    for k, v in tfe_workspace.bu_control : k => v.id
  }
}
```

### bu-control-workspace Module Changes

**Current Issues:**
- ⚠️ Uses external module sources (may have provider blocks)
- ❌ Hardcoded dependencies on external modules

**Required Changes:**

```hcl
# bu-control-workspace/variables.tf
variable "organization" {
  description = "TFC organization name"
  type        = string
}

variable "bu_name" {
  description = "Business unit name"
  type        = string
}

variable "project_id" {
  description = "TFC project ID for this BU (from platform stack)"
  type        = string
}

variable "admin_token" {
  description = "BU admin team token (from platform stack)"
  type        = string
  sensitive   = true
}

variable "yaml_config_path" {
  description = "Path to YAML configuration file"
  type        = string
}

variable "oauth_token_id" {
  description = "TFC OAuth token ID for VCS integration"
  type        = string
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

# Remove all provider blocks - configured by Stack
# Remove hardcoded module sources - may need to inline or publish dependencies
```

---

## Questions for You

Before proceeding with implementation, I need clarification on:

### 1. Organization Structure

**Question**: What is your HCP Terraform organization name and project structure?

- Organization name: `cloudbrokeraz`
- Platform team project name: `Platform_Team`
- Naming convention for BU projects: I'll let you decide!

### 2. Repository Hosting

**Question**: Where will you host these Stack repositories?

- [x] GitHub (same org as current repo?)
- [ ] GitLab
- [ ] Bitbucket
- [ ] Other: `__________`

**Repository URLs** (planned):
- Platform Stack: `https://github.com/CloudbrokerAz/tfc-platform-stack`
- BU Stack: I'll let you decide! can you create or do you need me to?

### 3. Module Registry

**Question**: PMR configuration details?

- PMR organization (may differ from TFC org): `cloudbrokeraz`
- Module naming preference:
  - [ ] `tenant-config` and `bu-control` (current)
  - [x] `platform-onboarding` and `bu-onboarding`
  - [ ] Other: `__________`

### 4. Authentication Strategy

**Question**: How will you authenticate Stacks to TFE?

- [x] OIDC with TFE provider (recommended)
- [ ] Static team tokens
- [ ] Variable sets with tokens

**If OIDC**:
- Do you have OIDC configured in HCP Terraform? `__________`
- Audience value: `__________`

### 5. YAML Configuration Strategy

**Question**: How should BU teams provide YAML configurations?

- [x] **Option A**: YAML files in bu-stack repository (finance.yaml, engineering.yaml)
- [ ] **Option B**: External repository BU teams control, bu-stack references it
- [ ] **Option C**: Variable sets with YAML content
- [ ] Other: `__________`

### 6. Deployment Strategy

**Question**: How many deployments per Stack?

**Platform Stack**:
- [ ] Single deployment (all BUs in one deployment)
- [x] One deployment per BU (dev, staging, prod)
- [ ] Other: `__________`

note: I want complete independence between BUs

**BU Stack**:
- [ ] One deployment per BU (finance, engineering, sales)
- [x] One deployment per BU per environment
- [ ] Other: `__________`

### 7. External Module Dependencies

**Question**: The bu-control-workspace module uses external modules:

```hcl
module "terraform-tfe-variable-sets" {
  source = "github.com/hashi-demo-lab/terraform-tfe-variable-sets?ref=v0.5.0"
}

module "github" {
  source = "github.com/hashi-demo-lab/terraform-github-repository-module?ref=0.5.1"
}

module "workspace" {
  source = "github.com/hashi-demo-lab/terraform-tfe-onboarding-module?ref=0.5.7"
}
```

**How should we handle these?**
- [ ] Inline the code into bu-control module
- [ ] Assume they'll be published to PMR and reference from there
- [ ] Keep as GitHub sources (Stacks support Git sources)
- [x] Refactor to reduce dependencies

### 8. Testing Strategy

**Question**: What testing priority?

- [ ] Full test suite migration (high priority)
- [ ] Basic validation tests only (medium priority)
- [x] Manual testing acceptable initially (low priority)

### 9. Migration Timeline

**Question**: When do you plan to deploy this?

- [ ] Proof of concept (PoC) phase
- [ ] Production migration (need backward compatibility)
- [x] Greenfield deployment (no existing workspaces)

### 10. Current Workspace Handling

**Question**: Do you have existing workspaces created by current modules?

- [ ] Yes - need migration path from workspace-based to Stacks
- [x] No - clean slate
- [ ] Some - need hybrid approach

---

## Recommended Next Steps

### Phase 1: Architecture Finalization (Current)
1. ✅ Read Stacks instructions
2. ✅ Assess current architecture
3. ⏳ Answer clarifying questions above
4. ⏳ Review and approve architecture design

### Phase 2: Repository Setup
1. Create platform-stack repository
2. Create bu-stack repository
3. Set up PMR integration for both repos
4. Configure VCS connections in HCP Terraform

### Phase 3: Module Refactoring
1. Refactor tenant-config module (remove providers, enhance outputs)
2. Refactor bu-control module (remove providers, handle dependencies)
3. Publish both modules to PMR with tag-based versioning
4. Validate module compatibility with Stacks

### Phase 4: Platform Stack Implementation
1. Create Stack configuration files (.tfcomponent.hcl, .tfdeploy.hcl)
2. Define components sourcing tenant-config from PMR
3. Configure outputs and publish_output blocks
4. Create example deployments
5. Test platform stack deployment

### Phase 5: BU Stack Implementation
1. Create Stack configuration files
2. Define upstream_input to platform stack
3. Configure components sourcing bu-control from PMR
4. Create per-BU deployments
5. Test BU stack with upstream inputs

### Phase 6: Documentation & Testing
1. Create linked stacks architecture guide
2. Migration guide from workspace-based pattern
3. Update README files for both stacks
4. Create deployment runbooks
5. Integration testing

### Phase 7: CI/CD & Automation
1. Stack-specific GitHub Actions workflows
2. Automated validation and testing
3. Deployment automation
4. Monitoring and alerting

---

## Key Takeaways

✅ **Repository split is REQUIRED** - 1:1 Stack-to-repo for linked stacks
✅ **Architecture is sound** - Platform → BU delegation pattern aligns with Stacks
✅ **Publish/upstream pattern is correct** - publish_output → upstream_input flow
✅ **Modules need minor refactoring** - Remove providers, enhance outputs
✅ **PMR publishing required** - Components source from private registry
✅ **YAML pattern preserved** - BU teams still use YAML-driven workspace creation
✅ **Deployment ordering matters** - Platform stack must deploy first

**Major Benefits of Stacks Migration:**

1. **Native Multi-Deployment Support** - dev/staging/prod per Stack
2. **Declarative Orchestration** - No need for manual workspace management
3. **Isolated State** - Each deployment has own state
4. **Enhanced Security** - OIDC authentication, ephemeral tokens
5. **Better Dependency Management** - Component-level dependencies
6. **Simplified Variable Flow** - publish_output → upstream_input pattern
7. **Deployment Groups** - Auto-approval rules per environment

**Challenges to Address:**

1. Repository split and migration
2. Module refactoring for Stacks compatibility
3. PMR publishing setup
4. OIDC authentication configuration
5. External module dependency handling
6. YAML configuration strategy
7. Testing across linked stacks
8. Documentation updates

---

## Ready to Proceed?

Once you answer the questions above, I'll:

1. Create detailed implementation plans for each phase
2. Generate all Stack configuration files
3. Refactor both modules for Stacks compatibility
4. Create comprehensive documentation
5. Set up CI/CD workflows
6. Build testing infrastructure

**Estimated Timeline:**
- Phase 2-3: 2-3 days (repository setup + module refactoring)
- Phase 4-5: 3-4 days (Stack implementation)
- Phase 6-7: 2-3 days (documentation + CI/CD)

**Total: 7-10 business days** for full Stacks migration with comprehensive testing and documentation.
