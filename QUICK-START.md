# 🚀 Quick Start Guide

**Get started with HCP Terraform onboarding in 3 steps!**

---

## Before You Start

You need:
- ✅ HCP Terraform organization (with admin access)
- ✅ GitHub organization (with admin access)
- ✅ This repository cloned
- ✅ One manual workspace already created (you have this: `tenant-config`)

---

## Step 1: Connect Your Bootstrap Workspace (5 minutes)

### In HCP Terraform UI

Navigate to your existing workspace:
- **Project**: `platform_team`
- **Workspace**: `tenant-config`

### Configure VCS Connection

```
Settings → Version Control → Connect to VCS

Repository:       CloudbrokerAz/hcp-terraform-onboarding
Branch:           main
Working Directory: tenant-config-project
Auto Apply:       ❌ Disabled (review changes first)
```

### Add Variables

```
Settings → Variables → Add Variable

Terraform Variables:
  tfc_organization_name = "your-hcp-terraform-org-name"
  business_unit        = "finance"
```

**✅ Done!** Your bootstrap workspace is now connected.

---

## Step 2: Add Business Unit Configuration (5 minutes)

### In Your Repository

Create YAML configuration for your first business unit:

```bash
cd tenant-config-project/config/

cat > finance.yaml <<'EOF'
bu: "finance"
description: "Finance team infrastructure"

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
          description: "Finance organization identifier"
  
  infrastructure:
    description: "Finance infrastructure workspaces"
    team_project_access:
      finance_sre:
        access: "admin"
EOF

git add config/finance.yaml
git commit -m "Add Finance BU configuration"
git push origin main
```

**✅ Done!** Configuration is ready.

---

## Step 3: Deploy Platform Infrastructure (5 minutes)

### In HCP Terraform UI

Navigate to your `tenant-config` workspace:

1. **Run is auto-triggered** by Git push (or click "Start new run")
2. **Review the plan** - You should see:
   - Team: `finance_admin`
   - Token: Generated for automation
   - Project: `finance_control`
   - Workspace: `finance_workspace_control`
   - Variable Set: `finance_admin` with TFE_TOKEN
   - Projects: `finance_applications`, `finance_infrastructure`

3. **Click "Confirm & Apply"**

### Verify Outputs

After apply completes, check outputs:

```hcl
bu_admin_team_ids       = { "finance" = "team-xxxxx" }
bu_control_project_ids  = { "finance" = "prj-xxxxx" }
consumer_project_ids    = { 
  "finance_applications" = "prj-xxxxx",
  "finance_infrastructure" = "prj-yyyyy"
}
```

**✅ Done!** Finance team infrastructure is ready!

---

## What You Just Created

```
HCP Terraform Organization
├── platform_team (project)
│   └── tenant-config (workspace) ← You configured this
│
├── finance_control (project) ← Created by Step 3
│   └── finance_workspace_control (workspace) ← Finance team uses this
│
├── finance_applications (project) ← Created by Step 3
│   └── (empty - Finance team will create workspaces here)
│
└── finance_infrastructure (project) ← Created by Step 3
    └── (empty - Finance team will create workspaces here)
```

---

## Next: Enable Finance Team Self-Service

The Finance team can now create their own workspaces! They should:

### 1. Create Their Control Repository

```bash
git clone https://github.com/YOUR-ORG/finance-bu-control.git
cd finance-bu-control

# Copy BU control module structure
# (or use module from Private Module Registry)
```

### 2. Add Workspace Configuration

```bash
mkdir -p config

cat > config/finance-app-dev.yaml <<'EOF'
workspace_name: "finance-app-dev"
workspace_description: "Finance app - development environment"
project_name: "applications"
workspace_terraform_version: "1.6.0"
workspace_tags: ["finance", "development"]

create_repo: true
github:
  github_repo_name: "finance-app-dev"
  github_repo_desc: "Finance Application - Dev"
  github_repo_visibility: "private"

vcs_repo:
  identifier: "YOUR-ORG/finance-app-dev"
  branch: "main"

variables:
  ENVIRONMENT:
    value: "development"
    category: "env"
EOF

git add config/finance-app-dev.yaml
git commit -m "Add dev workspace"
git push origin main
```

### 3. Configure Their Control Workspace

In HCP Terraform UI, navigate to `finance_workspace_control`:

```
Settings → Version Control → Connect to VCS
  Repository: YOUR-ORG/finance-bu-control
  Branch: main
  Working Directory: /

Settings → Variables
  # These are already available via variable set:
  ✅ TFE_TOKEN (from platform team)
  ✅ bu_projects (from platform team)
  
  # Add these as workspace variables:
  organization      = "your-org"
  github_org        = "your-github-org"
  github_org_owner  = "your-github-org"
  oauth_token_id    = "ot-xxxxxxxxxxxxx"
```

### 4. Apply

```
Actions → Start new run → Review → Confirm & Apply
```

**Result**: Finance now has:
- ✅ GitHub repo: `finance-app-dev`
- ✅ Workspace: `finance-app-dev` in `finance_applications` project
- ✅ VCS connection: Workspace connected to repo
- ✅ Ready to deploy infrastructure!

---

## Adding More Business Units

Want to onboard Engineering or Marketing?

```bash
# 1. Add YAML configuration
cp config/finance.yaml config/engineering.yaml
# Edit engineering.yaml with engineering projects

# 2. Update variable in bootstrap workspace
business_unit = "engineering"

# 3. Apply bootstrap workspace
# Engineering infrastructure created!

# 4. Engineering team follows same self-service steps
```

---

## Publishing to Private Module Registry (Optional)

Make modules reusable across your organization:

### Tag Your Repository

```bash
# Tag platform team module
git tag -a tenant-v1.0.0 -m "Release tenant-config v1.0.0"
git push origin tenant-v1.0.0

# Tag BU team module
git tag -a bu-v1.0.0 -m "Release bu-workspace v1.0.0"
git push origin bu-v1.0.0
```

### Publish to PMR

In HCP Terraform UI:

```
Registry → Publish → Module

Module 1 (Platform Team):
  Repository: CloudbrokerAz/hcp-terraform-onboarding
  Module Tag Prefix: tenant-
  Source Directory: tenant-config-project
  Module Name: tenant-config
  Provider: tfe

Module 2 (BU Team):
  Repository: CloudbrokerAz/hcp-terraform-onboarding
  Module Tag Prefix: bu-
  Source Directory: bu-control-workspace
  Module Name: bu-workspace
  Provider: tfe
```

**Result**: Modules available as:
- `app.terraform.io/YOUR-ORG/tenant-config/tfe`
- `app.terraform.io/YOUR-ORG/bu-workspace/tfe`

---

## Troubleshooting

### "Repository not found"
- Verify VCS provider is configured
- Ensure your account has admin access to repository
- Check repository name is correct

### "Variable not found"
- Verify variable set is attached to workspace
- Check variable names match exactly (case-sensitive)
- Ensure platform team has applied bootstrap workspace

### "Project not found"
- Check `bu_projects` variable contains correct mapping
- Verify project name in YAML matches platform configuration
- Ensure platform team workspace has completed apply

### More Help
See [WORKFLOW-TROUBLESHOOTING.md](.github/WORKFLOW-TROUBLESHOOTING.md) for detailed troubleshooting.

---

## Summary

You just:
1. ✅ Connected bootstrap workspace to Git
2. ✅ Defined Finance BU in YAML
3. ✅ Deployed platform infrastructure
4. ✅ Enabled Finance team self-service

**Total time: ~15 minutes**

---

## Learn More

| Document | Purpose |
|----------|---------|
| [QUESTIONS-ANSWERED.md](QUESTIONS-ANSWERED.md) | Answers to your PMR and bootstrap questions |
| [ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md) | Visual architecture diagrams |
| [SETUP-GUIDE.md](SETUP-GUIDE.md) | Complete production setup guide |
| [DEMO-GUIDE.md](DEMO-GUIDE.md) | Detailed demonstration walkthrough |
| [README.md](README.md) | Full documentation and examples |

---

**Ready to scale?** Add more BUs, publish to PMR, and enable organization-wide self-service! 🎉
