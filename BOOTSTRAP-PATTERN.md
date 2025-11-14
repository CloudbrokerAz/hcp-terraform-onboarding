# Bootstrap Workspace Pattern - Quick Reference

## The Answer: Keep Your Workspace!

**Your manually-created workspace is CORRECT!** This is the standard bootstrap pattern.

## Why This Works

```
┌─────────────────────────────────────────────────────┐
│ ONE-TIME MANUAL SETUP (You Already Did This! ✓)    │
│                                                     │
│  Project: platform_team (manually created)         │
│  Workspace: tenant-config (manually created)       │
│  Purpose: The "bootstrap workspace"                │
│                                                     │
│  This workspace deploys EVERYTHING else            │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Terraform Apply Creates ▼
                   │
┌──────────────────────────────────────────────────────┐
│ AUTOMATED PLATFORM INFRASTRUCTURE                    │
│                                                      │
│ For BU "finance":                                    │
│  ✓ Team: finance_admin                              │
│  ✓ Token: For automation                            │
│  ✓ Project: finance_control                         │
│  ✓ Workspace: finance_workspace_control ◄── BU uses │
│  ✓ Variable Set: TFE_TOKEN + bu_projects            │
│  ✓ Projects: finance_applications, etc.             │
└──────────────────────────────────────────────────────┘
```

## What To Do Now

### Step 1: Configure Your Existing Workspace

```bash
# In HCP Terraform UI:
# Navigate to: tenant-config workspace

# Settings → Version Control
VCS Branch: main
Working Directory: tenant-config-project
Auto-trigger runs: ✓ Enabled

# Settings → Variables
# Terraform Variables:
tfc_organization_name = "your-org-name"
business_unit        = "finance"
```

### Step 2: Add YAML Configuration

```bash
# In your repository: hcp-terraform-onboarding
cd tenant-config-project/config/

# Create finance.yaml
cat > finance.yaml <<'EOF'
bu: "finance"
description: "Finance team"
projects:
  applications:
    description: "Finance apps"
    team_project_access:
      finance_developers:
        access: "write"
EOF

git add config/finance.yaml
git commit -m "Add Finance BU"
git push origin main
```

### Step 3: Let It Run!

```bash
# HCP Terraform automatically triggers run
# Or manually: Queue Plan → Review → Apply
```

**Result**: Finance team now has their control workspace and can self-service!

## FAQ

### Q: Do I delete my manual workspace?
**A: NO!** Keep it. It's your bootstrap workspace.

### Q: How do I deploy multiple BUs?
**A:** Add more YAML files, change `business_unit` variable, apply again.

### Q: Where does the BU team configure their workspaces?
**A:** In the `finance_workspace_control` workspace (created by bootstrap).

### Q: Is this a chicken-egg problem?
**A:** No! The manual workspace is the "seed" that grows everything else.

## Visual: Before and After

### BEFORE (What You Have Now)
```
HCP Terraform:
  platform_team project:
    - tenant-config workspace (empty/manual)
```

### AFTER (After First Apply)
```
HCP Terraform:
  platform_team project:
    - tenant-config workspace ◄── Bootstrap (keep this!)
  
  finance_control project:
    - finance_workspace_control ◄── Finance BU uses this
  
  finance_applications project:
    - (empty - Finance team will create workspaces here)
```

## Complete Flow

```
1. Platform Team                 2. Bootstrap Workspace      3. Finance Team
   (You)                            (Terraform Apply)           (Self-Service)
   │                                │                           │
   │ Create YAML config             │                           │
   │ ─────────────────────────────> │                           │
   │                                │                           │
   │                                │ Create finance_admin      │
   │                                │ Create finance_control    │
   │                                │ Create finance_workspace_control
   │                                │ Create variable sets      │
   │                                │ ─────────────────────────>│
   │                                │                           │
   │                                │                           │ Add workspace YAML
   │                                │                           │ Apply in control workspace
   │                                │                           │ Workspaces created!
   │                                │                           │
   │ Update YAML                    │                           │
   │ ─────────────────────────────> │                           │
   │                                │ Update infrastructure     │
   │                                │ ─────────────────────────>│
```

## Key Insight

**You don't need to bootstrap the bootstrap workspace!**

The `tenant-config` workspace in `platform_team` project is manually created **ONCE** and then manages everything else through Infrastructure as Code.

This is the standard pattern for platform teams using HCP Terraform.

## See Also

- [SETUP-GUIDE.md](SETUP-GUIDE.md) - Detailed setup instructions
- [DEMO-GUIDE.md](DEMO-GUIDE.md) - Step-by-step demo walkthrough
- [README.md](README.md) - Architecture and usage documentation
