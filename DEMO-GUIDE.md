# 🎯 HCP Terraform Onboarding - Demo Walkthrough Guide

This guide provides a complete step-by-step demonstration of the HCP Terraform onboarding pattern, showcasing how platform teams can enable business units to self-service provision infrastructure.

## 📋 Table of Contents

- [Demo Overview](#demo-overview)
- [Prerequisites](#prerequisites)
- [Demo Scenario](#demo-scenario)
- [Part 1: Platform Team Setup](#part-1-platform-team-setup)
- [Part 2: Business Unit Onboarding](#part-2-business-unit-onboarding)
- [Part 3: Verification & Validation](#part-3-verification--validation)
- [Part 4: Advanced Features](#part-4-advanced-features)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Key Takeaways](#key-takeaways)

---

## Demo Overview

### What You'll Demonstrate

1. **Platform Team Layer** - Central infrastructure provisioning
   - Create BU admin teams
   - Provision BU control projects and workspaces
   - Set up variable sets with tokens
   - Delegate control to business units

2. **Business Unit Layer** - Self-service workspace creation
   - BU teams create their own workspaces
   - GitHub repository automation
   - VCS integration
   - Variable set management
   - RBAC configuration

3. **Key Benefits**
   - **Separation of concerns** - Platform vs BU responsibilities
   - **Self-service** - BU autonomy within guardrails
   - **Standardization** - Consistent patterns across teams
   - **Security** - Least privilege access model
   - **Auditability** - All changes tracked in Terraform state

### Demo Duration

- **Quick Demo**: 15-20 minutes (basic example)
- **Full Demo**: 30-45 minutes (complete example with advanced features)

---

## Prerequisites

### Required Access

- [ ] **HCP Terraform Organization** - Admin access
- [ ] **GitHub Organization** - Owner or admin access
- [ ] **Terraform CLI** - Version >= 1.6.0 installed
- [ ] **Git** - Installed and configured

### Required Credentials

```bash
# HCP Terraform
export TFE_TOKEN="your-hcp-terraform-token"
export TFE_ORGANIZATION="your-org-name"

# GitHub
export GITHUB_TOKEN="your-github-pat"
export GITHUB_ORG="your-github-org"

# OAuth Token ID (for VCS integration)
export OAUTH_TOKEN_ID="ot-xxxxxxxxxxxxx"
```

### Setup Validation

```bash
# Verify Terraform version
terraform version

# Verify credentials
echo $TFE_TOKEN | wc -c    # Should be > 10
echo $GITHUB_TOKEN | wc -c # Should be > 10

# Test HCP Terraform API access
curl -s -H "Authorization: Bearer $TFE_TOKEN" \
  https://app.terraform.io/api/v2/organizations/$TFE_ORGANIZATION | jq '.data.id'

# Test GitHub API access
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user | jq '.login'
```

---

## Demo Scenario

### Fictional Company: "Acme Corp"

**Challenge**: Acme Corp has 3 business units (Finance, Engineering, Marketing) that need to manage their own infrastructure while maintaining governance and security.

**Solution**: Implement HCP Terraform onboarding pattern:
- Platform team provisions foundational infrastructure
- Each BU gets their own control project and workspace
- BU teams self-service provision application workspaces

### Demo Personas

1. **Platform Team** (Alice) - Infrastructure platform engineer
2. **Finance BU Lead** (Bob) - Finance team lead needing infrastructure
3. **Engineering BU Lead** (Carol) - Engineering team lead needing workspaces

---

## Part 1: Platform Team Setup

### Step 1.1: Clone and Navigate to Repository

```bash
# Clone the repository
git clone https://github.com/CloudbrokerAz/hcp-terraform-onboarding.git
cd hcp-terraform-onboarding
```

### Step 1.2: Choose Your Demo Example

**Option A: Quick Demo (Basic Example)**

```bash
cd examples/basic/platform-team
```

**Option B: Full Demo (Complete Example)**

```bash
cd examples/complete/platform-team
```

### Step 1.3: Review Platform Team Configuration

```bash
# View the YAML configuration
cat config/finance.yaml
```

**Explain to audience:**
- YAML structure defines business unit
- Projects that will be created
- Team access levels
- Variable sets for configuration

### Step 1.4: Update Variables

```bash
# Edit terraform.tfvars
cat > terraform.tfvars <<EOF
tfc_organization_name = "$TFE_ORGANIZATION"
business_unit        = "finance"
EOF
```

### Step 1.5: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Explain what will be created:
# - Team: finance_admin
# - Team Token: For BU automation
# - Project: finance_control (control plane)
# - Projects: finance_applications, finance_infrastructure (consumer projects)
# - Variable Set: Contains TFE_TOKEN and bu_projects mapping
# - Workspace: finance_workspace_control (for BU self-service)

# Apply the configuration
terraform apply -auto-approve
```

### Step 1.6: Verify Platform Infrastructure

```bash
# Show created outputs
terraform output

# Explain key outputs:
terraform output bu_admin_team_ids       # Team ID for BU
terraform output bu_control_project_ids  # Control project ID
terraform output consumer_project_ids    # Application project IDs
terraform output bu_projects_mappings    # JSON mapping for BU use
```

**Show in HCP Terraform UI:**
1. Navigate to Teams → Show `finance_admin` team
2. Navigate to Projects → Show `finance_control` and consumer projects
3. Navigate to Workspaces → Show `finance_workspace_control`
4. Navigate to Variable Sets → Show `finance_admin` variable set
   - Highlight `TFE_TOKEN` (sensitive)
   - Highlight `bu_projects` (JSON mapping)

---

## Part 2: Business Unit Onboarding

### Step 2.1: Switch to BU Control Layer

```bash
# Navigate to BU control workspace
cd ../../bu-control/finance-bu
```

### Step 2.2: Review BU Configuration

```bash
# View workspace configuration
cat config/finance-app-dev.yaml
```

**Explain to audience:**
- BU teams manage these YAML files
- Self-service workspace creation
- GitHub repository automation
- VCS integration configuration
- Variable management

### Step 2.3: Configure BU Control Workspace

**Option A: Using Variable Set (Recommended)**

The platform team already provisioned:
- Team: `finance_admin`
- Variable Set: Contains `TFE_TOKEN` and `bu_projects`
- Workspace: `finance_workspace_control` with variable set attached

**In HCP Terraform UI:**
1. Navigate to `finance_workspace_control` workspace
2. Settings → Variable Sets → Verify `finance_admin` is attached
3. Variables → Verify `TFE_TOKEN` exists (from variable set)
4. Variables → Verify `bu_projects` exists (from variable set)

**Option B: Manual Configuration (for demo clarity)**

```bash
# Create terraform.tfvars with BU-specific values
cat > terraform.tfvars <<EOF
organization      = "$TFE_ORGANIZATION"
github_org        = "$GITHUB_ORG"
github_org_owner  = "$GITHUB_ORG"
oauth_token_id    = "$OAUTH_TOKEN_ID"
bu_projects       = $(terraform output -raw -state=../../platform-team/terraform.tfstate bu_projects_mappings | jq -r '.finance')
EOF

# The bu_projects should look like:
# {"applications":"prj-xxxxx","infrastructure":"prj-yyyyy"}
```

### Step 2.4: Initialize and Plan

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Explain what will be created:
# - GitHub Repository: finance-app-dev
# - Workspace: finance-app-dev
# - VCS Connection: Links workspace to GitHub repo
# - Variables: Application-specific variables
# - Variable Sets: If configured in YAML
```

### Step 2.5: Apply BU Configuration

```bash
# Apply the configuration
terraform apply -auto-approve
```

### Step 2.6: Verify BU Infrastructure

```bash
# Show created outputs
terraform output

# Key outputs to highlight:
terraform output workspace_ids              # Created workspace IDs
terraform output github_repository_urls     # GitHub repo URLs
terraform output variable_set_ids           # Variable set IDs
terraform output workspaces_with_repos      # Workspaces with VCS
```

**Show in HCP Terraform UI:**
1. Navigate to Projects → `finance_applications`
2. Show newly created workspace: `finance-app-dev`
3. Settings → Version Control → Show VCS connection
4. Settings → Variables → Show workspace variables

**Show in GitHub:**
1. Navigate to your GitHub organization
2. Find repository: `finance-app-dev`
3. Show template-based repository structure

---

## Part 3: Verification & Validation

### Step 3.1: Test Workspace Functionality

```bash
# Trigger a run in the new workspace (from HCP Terraform UI)
# 1. Queue a plan from UI
# 2. Show plan output
# 3. Show VCS-triggered runs work
```

### Step 3.2: Verify RBAC

**In HCP Terraform UI:**
1. Navigate to `finance-app-dev` workspace
2. Settings → Team Access
3. Verify `finance_admin` team has appropriate access
4. Show that other teams don't have access

### Step 3.3: Verify Variable Sets

```bash
# Show variable set associations
terraform output variable_set_workspace_associations
```

**In HCP Terraform UI:**
1. Navigate to Variable Sets → Show created variable sets
2. Click on a variable set
3. Show which workspaces it's applied to

### Step 3.4: Test Remote State Sharing

If configured in YAML:

```bash
# Navigate to consumer workspace
# Show in Settings → Remote State Sharing
# Verify remote state consumers are configured
```

---

## Part 4: Advanced Features

### Feature 1: Adding Additional Workspaces

```bash
# BU team adds new workspace configuration
cat > config/finance-app-staging.yaml <<EOF
workspace_name: "finance-app-staging"
workspace_description: "Finance application staging environment"
project_name: "applications"
workspace_terraform_version: "1.6.0"
workspace_tags: ["finance", "staging"]

create_repo: true
github:
  github_repo_name: "finance-app-staging"
  github_repo_desc: "Finance App - Staging"
  github_repo_visibility: "private"

# VCS Configuration
vcs_repo:
  identifier: "$GITHUB_ORG/finance-app-staging"
  branch: "main"

# Variables
variables:
  ENVIRONMENT:
    value: "staging"
    category: "env"
  AWS_REGION:
    value: "us-west-2"
    category: "terraform"
EOF

# Apply changes
terraform plan
terraform apply -auto-approve
```

### Feature 2: Variable Set Management

```bash
# Add variable set to existing workspace
cat > config/finance-app-dev.yaml <<EOF
# ... existing configuration ...

create_variable_set: true
var_sets:
  - variable_set_name: "finance-common-vars"
    variable_set_description: "Common variables for Finance workspaces"
    tags: ["finance", "common"]
    variables:
      DB_HOST:
        value: "db.finance.internal"
        category: "terraform"
      API_ENDPOINT:
        value: "https://api.finance.acme.com"
        category: "terraform"
        hcl: false
EOF

# Apply changes
terraform apply -auto-approve
```

### Feature 3: Agent Pool Configuration

```bash
# Configure workspace for agent execution
cat > config/finance-secure-workspace.yaml <<EOF
workspace_name: "finance-secure-workspace"
project_name: "infrastructure"

# Agent Configuration
workspace_agents: true
execution_mode: "agent"
agent_pool_name: "finance-secure-pool"

# ... rest of configuration ...
EOF

terraform apply -auto-approve
```

### Feature 4: Multi-Environment Setup

**Show scaling to multiple environments:**

```bash
# Finance BU now has:
# - finance-app-dev (created earlier)
# - finance-app-staging (just created)
# - Can easily add production

# Show how variable sets can be shared
# Show how RBAC differs per environment
# Show how remote state connects environments
```

---

## Troubleshooting

### Common Issues During Demo

#### Issue 1: OAuth Token Not Found

**Symptom**: `Error: OAuth token ot-xxxxx not found`

**Solution**:
```bash
# Verify OAuth token ID
echo $OAUTH_TOKEN_ID

# Check in HCP Terraform UI:
# Organization Settings → VCS Providers → Copy OAuth Token ID

# Update your terraform.tfvars
oauth_token_id = "ot-correct-token-id"
```

#### Issue 2: Project Not Found

**Symptom**: `Error: Project not found`

**Solution**:
```bash
# Verify bu_projects mapping is correct
terraform output -state=../platform-team/terraform.tfstate bu_projects_mappings

# Ensure project name matches exactly:
project_name: "applications"  # Must match YAML key in platform team config
```

#### Issue 3: GitHub Repository Already Exists

**Symptom**: `Repository already exists`

**Solution**:
```bash
# Option 1: Use different repository name
github_repo_name: "finance-app-dev-v2"

# Option 2: Import existing repository
terraform import 'module.github["workspace-name"].github_repository.this' finance-app-dev

# Option 3: Set create_repo to false
create_repo: false
```

#### Issue 4: Variable Set Association Fails

**Symptom**: `Error associating variable set with workspace`

**Solution**:
```bash
# Ensure workspace and variable set exist
terraform state list

# Check dependencies
terraform apply -target=module.terraform-tfe-variable-sets
terraform apply -target=module.workspace
terraform apply  # Now associate them
```

### Demo Recovery Steps

If something goes wrong during the demo:

1. **Take a breath** - Explain this is real infrastructure, issues happen
2. **Show the error** - Use it as a teaching moment
3. **Use verbose mode**:
   ```bash
   TF_LOG=DEBUG terraform apply
   ```
4. **Fall back to pre-built environment** - Have a backup org ready
5. **Jump to verification** - Skip to showing the end result

---

## Cleanup

### Step 1: Destroy BU Infrastructure

```bash
# Navigate to BU control workspace
cd examples/basic/bu-control/finance-bu

# Destroy BU-managed resources
terraform destroy -auto-approve
```

### Step 2: Destroy Platform Infrastructure

```bash
# Navigate to platform team workspace
cd ../../platform-team

# Destroy platform resources
terraform destroy -auto-approve
```

### Step 3: Manual Cleanup (if needed)

**In HCP Terraform UI:**
- Delete any lingering workspaces
- Remove variable sets
- Delete teams
- Remove projects

**In GitHub:**
- Delete created repositories (if desired)

---

## Key Takeaways

### For Platform Teams

✅ **Centralized Governance**
- Control BU access through team management
- Standardize project structure
- Enforce security policies

✅ **Self-Service Enablement**
- BUs can create workspaces independently
- Automated provisioning reduces ticket queues
- Guardrails prevent misconfigurations

✅ **Scalability**
- Add new BUs by adding YAML files
- Consistent patterns across teams
- Infrastructure as Code for all

### For Business Unit Teams

✅ **Autonomy**
- Create and manage own workspaces
- Control variables and configurations
- Own their application lifecycle

✅ **Simplicity**
- YAML-driven configuration
- No need to understand complex Terraform
- Self-documenting infrastructure

✅ **Integration**
- Automatic GitHub repo creation
- VCS-driven workflow
- Remote state sharing between workspaces

### For Leadership

✅ **Cost Efficiency**
- Reduce platform team overhead
- Faster time-to-market for BUs
- Reusable infrastructure patterns

✅ **Security & Compliance**
- Centralized access control
- Audit trail through Terraform state
- Least privilege access model

✅ **Developer Experience**
- Reduced friction for teams
- Standardized tooling
- Clear ownership boundaries

---

## Demo Tips & Best Practices

### Before the Demo

1. **Test everything** - Run through the demo completely at least once
2. **Pre-create OAuth tokens** - Have them ready to paste
3. **Clean environment** - Start with a fresh org or dedicated demo org
4. **Backup plan** - Have screenshots or video recording as fallback
5. **Time check** - Practice to fit your time slot

### During the Demo

1. **Start with the "why"** - Explain the problem being solved
2. **Show, don't just tell** - Navigate through UIs, run commands
3. **Highlight outputs** - Use `terraform output` liberally
4. **Explain as you type** - Narrate what you're doing
5. **Pause for questions** - Build in checkpoints
6. **Use real scenarios** - Make examples relatable to your audience

### After the Demo

1. **Share resources** - Links to repo, documentation, examples
2. **Offer follow-up** - Pair programming, office hours
3. **Gather feedback** - What resonated? What was confusing?
4. **Document issues** - Note any problems for future iterations
5. **Celebrate success** - This is complex stuff, be proud!

---

## Additional Demo Scenarios

### Scenario 1: Onboarding New Business Unit

Show how easy it is to onboard a new BU:

```bash
# Platform team adds new YAML file
cat > config/engineering.yaml <<EOF
bu: "engineering"
description: "Engineering team"
# ... projects ...
EOF

# Apply - creates all infrastructure for new BU
terraform apply -auto-approve

# 🎉 Engineering team now has their control plane
```

### Scenario 2: Promoting Workspace to Production

Show how a workspace moves from dev → staging → production:

```bash
# Same configuration, different workspace YAML
# Show how variables differ
# Show how RBAC differs
# Show how remote state consumers connect
```

### Scenario 3: Disaster Recovery

Show how to recover if workspace is accidentally deleted:

```bash
# Configuration is in Git
# Simply re-apply
terraform apply -auto-approve

# Workspace recreated with exact same configuration
```

---

## Presentation Slide Suggestions

### Slide 1: Title
**HCP Terraform Onboarding Pattern**
*Self-Service Infrastructure for Business Units*

### Slide 2: The Challenge
- Multiple teams need infrastructure
- Platform team overwhelmed with requests
- No self-service capability
- Inconsistent patterns

### Slide 3: The Solution
- Two-tier architecture
- Platform team provisions foundation
- BU teams self-service workspaces
- YAML-driven configuration

### Slide 4: Architecture Diagram
```
┌─────────────────────────────────────┐
│     Platform Team (Admins)          │
│  ┌─────────────────────────────┐   │
│  │  tenant-config-project      │   │
│  │  - Creates BU teams         │   │
│  │  - Provisions control plane │   │
│  │  - Delegates access         │   │
│  └─────────────────────────────┘   │
└──────────────┬──────────────────────┘
               │ Provisions
               ▼
┌─────────────────────────────────────┐
│   Business Unit (Self-Service)      │
│  ┌─────────────────────────────┐   │
│  │  bu-control-workspace       │   │
│  │  - Creates workspaces       │   │
│  │  - Manages GitHub repos     │   │
│  │  - Configures VCS           │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Slide 5: Demo Time!
[Live Demo]

### Slide 6: Key Benefits
- Separation of Concerns
- Self-Service
- Standardization
- Security
- Scalability

### Slide 7: Getting Started
- GitHub: [repo link]
- Documentation: [docs link]
- Examples: [examples link]
- Questions: [contact info]

---

## Appendix

### A. Environment Variables Reference

```bash
# Required
export TFE_TOKEN="xxxxx"               # HCP Terraform user/team token
export TFE_ORGANIZATION="my-org"       # HCP Terraform organization name
export GITHUB_TOKEN="ghp_xxxxx"        # GitHub personal access token
export GITHUB_ORG="my-github-org"      # GitHub organization name
export OAUTH_TOKEN_ID="ot-xxxxx"       # OAuth token for VCS

# Optional
export TF_LOG="DEBUG"                  # Enable debug logging
export TF_LOG_PATH="terraform.log"     # Log to file
```

### B. Quick Reference Commands

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Destroy
terraform destroy -auto-approve

# Show outputs
terraform output

# Show specific output
terraform output -json bu_projects_mappings | jq

# Format code
terraform fmt -recursive

# Validate
terraform validate

# Show state
terraform state list

# Import existing
terraform import <resource> <id>
```

### C. YAML Configuration Templates

See `examples/` directory for complete templates.

### D. Troubleshooting Checklist

- [ ] Terraform version >= 1.6.0
- [ ] All environment variables set
- [ ] API credentials valid
- [ ] OAuth token accessible
- [ ] GitHub org has correct permissions
- [ ] HCP Terraform org has available capacity
- [ ] Network connectivity to APIs
- [ ] Pre-commit hooks disabled (for demo)

---

**End of Demo Guide**

*For questions, issues, or contributions:*
- **GitHub**: https://github.com/CloudbrokerAz/hcp-terraform-onboarding
- **Issues**: https://github.com/CloudbrokerAz/hcp-terraform-onboarding/issues
- **Discussions**: https://github.com/CloudbrokerAz/hcp-terraform-onboarding/discussions

**Good luck with your demo! 🚀**
