# 🚀 HCP Terraform Onboarding - Complete Setup Guide

This guide walks you through setting up this module for production use, covering both the Private Module Registry (PMR) publishing and the bootstrap/"chicken-and-egg" problem.

## 📋 Table of Contents

1. [Repository Structure Validation](#repository-structure-validation)
2. [Publishing to Private Module Registry](#publishing-to-private-module-registry)
3. [Bootstrap Strategy (Solving the Chicken-and-Egg Problem)](#bootstrap-strategy)
4. [Production Deployment](#production-deployment)
5. [Maintenance and Updates](#maintenance-and-updates)

---

## Repository Structure Validation

### ✅ Is This Repository PMR-Ready?

**YES!** This repository already follows all HashiCorp best practices for private module registry publishing:

#### Required Structure (All Present ✓)

```
✅ Standard module naming: terraform-<provider>-<name>
   - tenant-config-project (embedded module)
   - bu-control-workspace (embedded module)

✅ Standard file structure:
   - *.tf files in root
   - README.md
   - CHANGELOG.md
   - LICENSE
   - examples/ directory
   - tests/ directory

✅ Semantic versioning ready:
   - CHANGELOG.md initialized
   - Version tags in format: v1.0.0

✅ Documentation:
   - Comprehensive README
   - Input/output documentation
   - Usage examples
   - Test documentation
```

#### Module Organization

This repository contains **TWO modules** that should be published **separately**:

1. **Platform Team Module**: `tenant-config-project/`
2. **BU Team Module**: `bu-control-workspace/`

### Repository Naming Recommendations

For optimal PMR compatibility, consider renaming repositories:

**Current Structure** (Monorepo):
```
hcp-terraform-onboarding/
├── tenant-config-project/    # Module 1
└── bu-control-workspace/     # Module 2
```

**Recommended Structure** (Separate Repos):

```
Option 1: Separate Repositories (Best Practice)
├── terraform-tfe-tenant-config/       # Platform team module
└── terraform-tfe-bu-workspace/        # BU team module

Option 2: Monorepo with Tag Prefixes (Current - Also Valid)
└── hcp-terraform-onboarding/
    ├── tenant-config-project/
    └── bu-control-workspace/
```

**Recommendation**: Keep the current monorepo structure and use **module tag prefixes** for publishing. This is valid and documented in HashiCorp best practices.

---

## Publishing to Private Module Registry

### Prerequisites

#### 1. VCS Provider Configuration

Ensure GitHub (or your VCS) is connected to HCP Terraform:

1. Navigate to: **Organization Settings** → **VCS Providers**
2. If not configured, click **Add VCS Provider**
3. Choose **GitHub.com** (or GitHub Enterprise)
4. Complete OAuth connection
5. **Grant admin access** to this repository

#### 2. Registry Administrator Permissions

Create a dedicated team for registry management:

```bash
# In HCP Terraform UI:
# 1. Settings → Teams → Create Team
# 2. Team Name: "platform-team-registry-admins"
# 3. Organization Permissions → Enable "Manage private registry"
```

**Best Practice**: Use a team API token for CI/CD automation (future state).

#### 3. Tag Your Repository

Since this is a monorepo with two modules, use **tag prefixes**:

```bash
# For tenant-config-project module
git tag -a tenant-v1.0.0 -m "Release tenant-config-project v1.0.0"
git push origin tenant-v1.0.0

# For bu-control-workspace module
git tag -a bu-v1.0.0 -m "Release bu-control-workspace v1.0.0"
git push origin bu-v1.0.0
```

### Publishing Process

#### Publish Platform Team Module (tenant-config-project)

1. **Navigate to Registry**
   - Go to: **Registry** → **Publish** → **Module**

2. **Select Repository**
   - VCS Provider: `GitHub.com` (or your VCS)
   - Repository: `CloudbrokerAz/hcp-terraform-onboarding`

3. **Configure Module Settings**
   - **Publishing Type**: `Tag` (recommended) or `Branch` (for testing)
   
   **For Tag-Based Publishing**:
   - **Module Tag Prefix**: `tenant-`
   - **Source Directory**: `tenant-config-project`
   
4. **Module Details**
   - **Module Name**: `tenant-config`
   - **Provider Name**: `tfe`
   - **No-Code Ready**: `Disabled` (this is IaC-only)

5. **Click "Publish Module"**

#### Publish BU Team Module (bu-control-workspace)

Repeat the process with these settings:

- **Module Tag Prefix**: `bu-`
- **Source Directory**: `bu-control-workspace`
- **Module Name**: `bu-workspace`
- **Provider Name**: `tfe`

### Resulting Module Addresses

Once published, your modules will be addressable as:

```hcl
# Platform Team Module
module "tenant_config" {
  source  = "app.terraform.io/YOUR-ORG/tenant-config/tfe"
  version = "~> 1.0.0"
  
  # ... configuration ...
}

# BU Team Module
module "bu_workspace" {
  source  = "app.terraform.io/YOUR-ORG/bu-workspace/tfe"
  version = "~> 1.0.0"
  
  # ... configuration ...
}
```

### Publishing Workflow Diagram

```
┌─────────────────────────────────────┐
│  Developer Workflow                 │
│  1. Make changes                    │
│  2. Update CHANGELOG.md             │
│  3. Create PR                       │
│  4. Merge to main                   │
│  5. Create release tag              │
│     git tag tenant-v1.1.0           │
│     git push origin tenant-v1.1.0   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  HCP Terraform Registry             │
│  - Webhook triggered                │
│  - Downloads source code            │
│  - Generates documentation          │
│  - Publishes new version            │
└─────────────────────────────────────┘
```

---

## Bootstrap Strategy (Solving the Chicken-and-Egg Problem)

### The Problem

You have a **chicken-and-egg scenario**:

1. ❓ You need a workspace to deploy the platform team infrastructure
2. ❓ But the platform team module creates workspaces
3. ❓ Do you delete your manually-created `tenant-config` workspace in `platform_team` project?

### The Solution: Bootstrap Workspace Pattern

**Answer**: **Keep your manually-created workspace!** This is the correct pattern.

#### Architecture Overview

```
┌───────────────────────────────────────────────────────┐
│  BOOTSTRAP LAYER (Manual Setup - One Time)            │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Project: platform_team                         │ │
│  │  Workspace: tenant-config                       │ │
│  │  Purpose: Deploy platform infrastructure        │ │
│  │  VCS: Connected to this repo                    │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────┬────────────────────────────────────────┘
               │ Creates ▼
┌──────────────────────────────────────────────────────┐
│  PLATFORM LAYER (Automated via Bootstrap Workspace)  │
│  ┌────────────────────────────────────────────────┐ │
│  │  For Each Business Unit (BU):                  │ │
│  │  - Team: {bu}_admin                            │ │
│  │  - Token: For BU automation                    │ │
│  │  - Project: {bu}_control                       │ │
│  │  - Workspace: {bu}_workspace_control           │ │
│  │  - Variable Set: TFE_TOKEN + bu_projects       │ │
│  │  - Consumer Projects: {bu}_{project}           │ │
│  └────────────────────────────────────────────────┘ │
└──────────────┬───────────────────────────────────────┘
               │ BU Teams Use ▼
┌──────────────────────────────────────────────────────┐
│  BU LAYER (Self-Service Workspaces)                  │
│  ┌────────────────────────────────────────────────┐ │
│  │  BU Control Workspace: {bu}_workspace_control  │ │
│  │  Purpose: Create BU workspaces                 │ │
│  │  VCS: Connected to BU-managed repo/branch      │ │
│  │  Credentials: From platform variable set       │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### Step-by-Step Bootstrap Setup

#### Phase 1: Bootstrap Workspace Configuration

**Your existing workspace is CORRECT! Just configure it properly:**

1. **Keep Your Workspace**: `tenant-config` in `platform_team` project

2. **Configure VCS Connection**:
   - Go to workspace settings
   - **Version Control** → **Connect to VCS**
   - Select repository: `CloudbrokerAz/hcp-terraform-onboarding`
   - **VCS Branch**: `main`
   - **Terraform Working Directory**: `tenant-config-project`
   - **Automatic Run Triggering**: Enable

3. **Configure Variables**:

   **Terraform Variables**:
   ```hcl
   tfc_organization_name = "your-org-name"
   business_unit        = "finance"  # Your first BU
   ```

   **Environment Variables**:
   ```bash
   # Not needed - workspace runs within HCP Terraform
   # Credentials are implicit
   ```

4. **Configure Workspace Settings**:
   - **Auto Apply**: `false` (for safety - platform team reviews)
   - **Terraform Version**: `>= 1.6.0`
   - **Execution Mode**: `Remote`

#### Phase 2: Add Business Unit YAML Configuration

In your repository, create BU configuration files:

```bash
# In your repository
cd tenant-config-project/config/

# Create your first BU configuration
cat > finance.yaml <<EOF
bu: "finance"
description: "Finance team infrastructure"

# Optional SSO team integration
# team:
#   sso_team_id: "team-abc123"

# Projects to create for Finance BU
projects:
  applications:
    description: "Finance application workspaces"
    team_project_access:
      finance_developers:
        access: "write"
      finance_leads:
        access: "admin"
    
    var_sets:
      variables:
        FINANCE_ORG_ID:
          value: "12345"
          category: "env"
          description: "Finance organization ID"
  
  infrastructure:
    description: "Finance infrastructure workspaces"
    team_project_access:
      finance_sre:
        access: "admin"
      finance_developers:
        access: "read"
EOF

# Commit and push
git add config/finance.yaml
git commit -m "Add Finance BU configuration"
git push origin main
```

#### Phase 3: Deploy Platform Infrastructure

```bash
# HCP Terraform automatically triggers a run when you push
# Or manually trigger via UI:
# 1. Navigate to workspace: tenant-config
# 2. Click "Actions" → "Start new run"
# 3. Review plan
# 4. Confirm and apply
```

**What Gets Created**:
- Team: `finance_admin`
- Team Token: Stored in variable set
- Project: `finance_control`
- Workspace: `finance_workspace_control`
- Variable Set: `finance_admin` with:
  - `TFE_TOKEN` (sensitive)
  - `bu_projects` (JSON mapping)
- Consumer Projects:
  - `finance_applications`
  - `finance_infrastructure`

#### Phase 4: Configure BU Control Workspace

**Option A: Manual VCS Setup (Recommended)**

1. **Create BU Repository**:
   ```bash
   # Create new repo in GitHub: finance-bu-control
   git clone https://github.com/YOUR-ORG/finance-bu-control.git
   cd finance-bu-control
   
   # Copy BU control module structure
   cp -r /path/to/hcp-terraform-onboarding/bu-control-workspace/* .
   
   # Create initial workspace configuration
   mkdir -p config
   cat > config/finance-app-dev.yaml <<EOF
   workspace_name: "finance-app-dev"
   workspace_description: "Finance app development environment"
   project_name: "applications"
   workspace_terraform_version: "1.6.0"
   workspace_tags: ["finance", "development"]
   
   create_repo: true
   github:
     github_repo_name: "finance-app-dev"
     github_repo_desc: "Finance Application - Development"
     github_repo_visibility: "private"
   
   vcs_repo:
     identifier: "YOUR-ORG/finance-app-dev"
     branch: "main"
   
   variables:
     ENVIRONMENT:
       value: "development"
       category: "env"
   EOF
   
   git add .
   git commit -m "Initial BU control configuration"
   git push origin main
   ```

2. **Configure BU Control Workspace VCS**:
   - Navigate to workspace: `finance_workspace_control`
   - Settings → Version Control → Connect to VCS
   - Repository: `YOUR-ORG/finance-bu-control`
   - Branch: `main`
   - Working Directory: `/` (root)
   - Automatic Run Triggering: Enable

3. **Verify Variable Set Attached**:
   - Navigate to: `finance_workspace_control`
   - Settings → Variable Sets
   - Verify `finance_admin` is attached ✓
   - Variables should show:
     - `TFE_TOKEN` (from variable set)
     - `bu_projects` (from variable set)

4. **Add Additional Variables**:
   
   Add these as **workspace variables** (not in variable set):
   
   ```hcl
   # Terraform Variables
   organization      = "your-org-name"
   github_org        = "your-github-org"
   github_org_owner  = "your-github-org"
   oauth_token_id    = "ot-xxxxxxxxxxxxx"
   
   # bu_projects comes from variable set automatically
   ```

**Option B: Use Module from PMR (After Publishing)**

Once modules are in PMR, create a wrapper configuration:

```hcl
# In finance-bu-control repo: main.tf
module "bu_workspaces" {
  source  = "app.terraform.io/YOUR-ORG/bu-workspace/tfe"
  version = "~> 1.0.0"
  
  organization      = var.organization
  github_org        = var.github_org
  github_org_owner  = var.github_org_owner
  oauth_token_id    = var.oauth_token_id
  bu_projects       = var.bu_projects  # From variable set
}
```

#### Phase 5: Deploy BU Workspaces

```bash
# In HCP Terraform UI:
# 1. Navigate to workspace: finance_workspace_control
# 2. Queue plan
# 3. Review what will be created:
#    - GitHub repo: finance-app-dev
#    - Workspace: finance-app-dev
#    - VCS connection
# 4. Apply
```

### Configuration Management Pattern

```
Repository Structure:

┌──────────────────────────────────────────────┐
│  Platform Team Repository                    │
│  (CloudbrokerAz/hcp-terraform-onboarding)    │
│                                              │
│  tenant-config-project/                      │
│  ├── main.tf                                 │
│  ├── variables.tf                            │
│  ├── outputs.tf                              │
│  └── config/                                 │
│      ├── finance.yaml       ← Platform team  │
│      ├── engineering.yaml   ← Platform team  │
│      └── marketing.yaml     ← Platform team  │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│  Finance BU Repository                       │
│  (YOUR-ORG/finance-bu-control)               │
│                                              │
│  ├── main.tf (calls module or local code)   │
│  ├── variables.tf                            │
│  ├── terraform.tfvars                        │
│  └── config/                                 │
│      ├── finance-app-dev.yaml    ← BU team  │
│      ├── finance-app-staging.yaml← BU team  │
│      └── finance-app-prod.yaml   ← BU team  │
└──────────────────────────────────────────────┘
```

---

## Production Deployment

### Deployment Checklist

#### Pre-Deployment

- [ ] VCS provider configured with admin access
- [ ] Registry admin team created with permissions
- [ ] Both modules published to PMR
- [ ] Bootstrap workspace (`tenant-config`) created and configured
- [ ] First BU YAML configuration ready

#### Platform Team Deployment

```bash
# 1. Configure bootstrap workspace VCS
# 2. Add YAML configurations for BUs
# 3. Queue plan in HCP Terraform
# 4. Review outputs:
terraform output bu_admin_team_ids
terraform output bu_control_project_ids
terraform output bu_projects_mappings
# 5. Apply
```

#### BU Team Onboarding

```bash
# For each BU:
# 1. Platform team creates BU YAML config
# 2. Platform team applies bootstrap workspace
# 3. BU team creates their control repo
# 4. BU team configures their control workspace VCS
# 5. BU team adds workspace YAML configs
# 6. BU team applies control workspace
```

### Security Considerations

#### 1. Token Management

✅ **Platform Team Tokens**:
- Stored in variable sets (encrypted)
- Automatically available to BU control workspaces
- Rotatable via platform team workspace

✅ **GitHub OAuth Tokens**:
- Stored in HCP Terraform VCS settings
- Organization-level, not workspace-level
- Managed by platform team

#### 2. RBAC

✅ **Platform Team**:
- Admin on `platform_team` project
- Read access to BU control projects (for support)

✅ **BU Admin Teams**:
- Admin on their `{bu}_control` project
- Admin on their control workspace
- Write access to their consumer projects

✅ **BU Application Teams**:
- Configured per workspace via RBAC settings
- Read/Write/Plan access as defined in YAML

#### 3. State Isolation

✅ **Separate State Files**:
- Platform team state: In `tenant-config` workspace
- Each BU control state: In `{bu}_workspace_control`
- Each BU workspace state: In individual workspaces

✅ **Remote State Sharing**:
- Configured per workspace in YAML
- Only explicit consumers can read
- Read-only access enforced

---

## Maintenance and Updates

### Updating Modules

#### For Platform Team Module

```bash
# 1. Make changes to tenant-config-project/
# 2. Update CHANGELOG.md
# 3. Create PR and merge
# 4. Tag new version
git tag -a tenant-v1.1.0 -m "Add SSO team support"
git push origin tenant-v1.1.0

# 5. HCP Terraform auto-publishes to PMR
# 6. Bootstrap workspace auto-updates (if using module source)
# 7. Or: Bootstrap workspace uses local code (no change needed)
```

#### For BU Team Module

```bash
# 1. Make changes to bu-control-workspace/
# 2. Update CHANGELOG.md
# 3. Create PR and merge
# 4. Tag new version
git tag -a bu-v1.1.0 -m "Add agent pool support"
git push origin bu-v1.1.0

# 5. HCP Terraform auto-publishes to PMR
# 6. Each BU team updates their version constraint:
#    version = "~> 1.1.0"
```

### Adding New Business Units

```bash
# 1. Platform team creates new YAML config
cat > tenant-config-project/config/engineering.yaml <<EOF
bu: "engineering"
description: "Engineering team infrastructure"
projects:
  applications:
    description: "Engineering workspaces"
    # ... configuration ...
EOF

# 2. Commit and push
git add config/engineering.yaml
git commit -m "Onboard Engineering BU"
git push origin main

# 3. Bootstrap workspace auto-runs
# 4. Engineering team gets:
#    - engineering_admin team
#    - engineering_control project
#    - engineering_workspace_control workspace
#    - engineering_applications project
```

### Scaling Considerations

#### Small Organizations (< 10 BUs)

✅ **Monorepo Approach** (Current Structure):
- Single repository for both modules
- Tag prefixes for versioning
- Platform team manages all code

#### Large Organizations (> 10 BUs)

✅ **Separate Repositories**:
- `terraform-tfe-tenant-config` (platform team module)
- `terraform-tfe-bu-workspace` (BU team module)
- Each BU has their own control repo

✅ **Module Versioning**:
- Platform team module: Stable, infrequent updates
- BU team module: More frequent updates
- Version constraints protect BUs from breaking changes

---

## Quick Reference

### Repository to Workspace Mapping

| Repository | Module | Published As | Used By Workspace |
|------------|--------|--------------|-------------------|
| `hcp-terraform-onboarding` | `tenant-config-project/` | `app.terraform.io/ORG/tenant-config/tfe` | `tenant-config` (bootstrap) |
| `hcp-terraform-onboarding` | `bu-control-workspace/` | `app.terraform.io/ORG/bu-workspace/tfe` | `{bu}_workspace_control` |
| `finance-bu-control` | Wrapper config | N/A | `finance_workspace_control` |

### Key Commands

```bash
# Publish new module version
git tag -a tenant-v1.0.0 -m "Release message"
git push origin tenant-v1.0.0

# Check module in registry (API)
curl -H "Authorization: Bearer $TFE_TOKEN" \
  https://app.terraform.io/api/v2/organizations/YOUR-ORG/registry-modules

# Trigger workspace run (API)
curl -X POST \
  -H "Authorization: Bearer $TFE_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"runs","relationships":{"workspace":{"data":{"type":"workspaces","id":"WORKSPACE_ID"}}}}}' \
  https://app.terraform.io/api/v2/runs
```

### Troubleshooting

See [WORKFLOW-TROUBLESHOOTING.md](.github/WORKFLOW-TROUBLESHOOTING.md) for detailed troubleshooting steps.

---

## Next Steps

1. ✅ **Validate repository structure** (already done)
2. ✅ **Publish modules to PMR** (follow publishing process)
3. ✅ **Configure bootstrap workspace** (keep your `tenant-config` workspace)
4. ✅ **Deploy first BU** (Finance team example)
5. ✅ **Enable BU self-service** (Finance team deploys workspaces)
6. ✅ **Scale to additional BUs** (repeat for Engineering, Marketing, etc.)

---

**Questions?** See [DEMO-GUIDE.md](DEMO-GUIDE.md) for a step-by-step demonstration walkthrough!
