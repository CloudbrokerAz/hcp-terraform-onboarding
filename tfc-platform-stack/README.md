# Platform Stack - HCP Terraform Onboarding

Terraform Stack for **platform team** to onboard business units to HCP Terraform with automated GitHub repository creation and Stack configuration seeding.

## Overview

This Stack creates foundational HCP Terraform infrastructure for business units and automatically provisions turnkey GitHub repositories containing complete Terraform Stack configurations for BU teams.

**What This Stack Does**:
1. ✅ Creates BU control projects, teams, and tokens in HCP Terraform
2. ✅ Creates consumer projects from YAML configs
3. ✅ Creates GitHub repositories for each BU Stack
4. ✅ Seeds 8+ configuration files in each BU repo (Stack configs, YAML examples, CI/CD)
5. ✅ Publishes outputs for BU Stacks to consume via `upstream_input`

## Architecture

```
Platform Stack (this repo)
  ├─ Component: platform-onboarding module
  │  ├─ Creates: BU projects, teams, tokens, variable sets
  │  ├─ Creates: GitHub repos (tfc-finance-bu-stack, tfc-engineering-bu-stack, tfc-sales-bu-stack)
  │  └─ Seeds: Complete Stack configs in each repo
  │
  └─ Deployments (3):
     ├─ finance (publishes outputs)
     ├─ engineering (publishes outputs)
     └─ sales (publishes outputs)
                ↓
          (upstream_input)
                ↓
     BU Stacks (auto-created repos)
       ↓
       └─ BU teams manage their workspaces via YAML
```

## Stack Structure

```
tfc-platform-stack/
├── variables.tfcomponent.hcl       # Stack input variables
├── providers.tfcomponent.hcl        # TFE + GitHub providers with OIDC
├── components.tfcomponent.hcl       # Sources platform-onboarding from PMR
├── outputs.tfcomponent.hcl          # Stack outputs (automatically published)
├── deployments.tfdeploy.hcl         # 3 deployments (finance, engineering, sales)
├── config/
│   ├── finance.yaml                 # Finance BU configuration
│   ├── engineering.yaml             # Engineering BU configuration
│   └── sales.yaml                   # Sales BU configuration
└── README.md                        # This file
```

## Requirements

- **Terraform**: >= 1.13.5
- **HCP Terraform Organization**: cloudbrokeraz
- **HCP Terraform Project**: Platform_Team
- **GitHub Organization**: CloudbrokerAz
- **OIDC Audience**: platform.onboarding (configured in AWS/Azure/GCP)
- **GitHub Token**: PAT with `repo` and `admin:org` scopes

## Configuration

### YAML Files

The `config/*.yaml` files define BU-specific infrastructure to be created by the platform-onboarding module:

- **config/finance.yaml** - Finance BU projects and consumer projects
- **config/engineering.yaml** - Engineering BU projects and consumer projects
- **config/sales.yaml** - Sales BU projects and consumer projects

Each YAML file contains:
```yaml
business_unit: <bu_name>
projects:
  - name: <project_name>
    description: <description>
    var_sets:
      variables:
        - key: <var_name>
          value: <var_value>
          category: terraform
    workspaces: []  # For platform stack, typically empty
```

### Deployments

Three deployments create infrastructure for each BU:

1. **finance** - Filtered to `business_unit: finance`
2. **engineering** - Filtered to `business_unit: engineering`
3. **sales** - Filtered to `business_unit: sales`

Each deployment:
- Uses OIDC authentication with `platform.onboarding` audience
- Creates BU control project (e.g., `BU_finance`)
- Creates consumer projects from YAML
- Creates GitHub repository (e.g., `tfc-finance-bu-stack`)
- Seeds Stack configuration files in GitHub repo
- Publishes outputs for BU Stack consumption

### GitHub Repositories Created

| BU | Repository | Contents |
|----|------------|----------|
| Finance | `tfc-finance-bu-stack` | Complete Stack config + finance.yaml example |
| Engineering | `tfc-engineering-bu-stack` | Complete Stack config + engineering.yaml example |
| Sales | `tfc-sales-bu-stack` | Complete Stack config + sales.yaml example |

Each repository includes:
- ✅ `README.md` - BU-specific documentation
- ✅ `variables.tfcomponent.hcl` - Stack variables
- ✅ `providers.tfcomponent.hcl` - TFE provider with OIDC
- ✅ `components.tfcomponent.hcl` - Sources bu-onboarding module
- ✅ `outputs.tfcomponent.hcl` - Stack outputs
- ✅ `deployments.tfdeploy.hcl` - Dev/staging/prod deployments with `upstream_input`
- ✅ `configs/<bu_name>.yaml` - Example workspace configuration
- ✅ `.github/workflows/terraform-stacks.yml` - CI/CD workflow

## Prerequisites

### 1. OIDC Configuration

Configure OIDC trust relationship in your cloud provider with audience: **platform.onboarding**

**AWS Example** (Trust Policy):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/app.terraform.io"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "app.terraform.io:aud": "platform.onboarding"
        },
        "StringLike": {
          "app.terraform.io:sub": "organization:cloudbrokeraz:project:Platform_Team:*"
        }
      }
    }
  ]
}
```

### 2. GitHub Token

Create GitHub Personal Access Token (PAT) with scopes:
- ✅ `repo` - Full repository access
- ✅ `admin:org` - Organization management (create teams, repos)
- ✅ `workflow` - Update GitHub Actions workflows

Store in HCP Terraform variable set (ephemeral, sensitive).

### 3. Module Publishing

Publish `platform-onboarding` module to Private Module Registry:
```bash
cd platform-onboarding
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Configure in HCP Terraform Registry:
- Organization: cloudbrokeraz
- Module name: platform-onboarding
- Provider: tfe

Update `components.tfcomponent.hcl` version constraint after publishing.

## Deployment

### Initial Deployment

1. **Create HCP Terraform Stack**:
   - Organization: cloudbrokeraz
   - Project: Platform_Team
   - Stack name: platform-stack
   - VCS: Connect to this repository

2. **Configure Variable Set** (recommended):
   Create variable set with:
   - `github_token` (ephemeral, sensitive)
   - `TFE_TOKEN` (ephemeral, sensitive) - if using CLI

3. **Plan Deployments**:
   ```bash
   terraform stacks providers-lock
   terraform stacks validate
   terraform stacks plan --deployment=finance
   terraform stacks plan --deployment=engineering
   terraform stacks plan --deployment=sales
   ```

4. **Apply Deployments**:
   Apply via HCP Terraform UI after reviewing plans.

### Verification

After successful deployment, verify:

1. **HCP Terraform Projects Created**:
   - BU_finance
   - BU_engineering
   - BU_sales

2. **GitHub Repositories Created**:
   - tfc-finance-bu-stack
   - tfc-engineering-bu-stack
   - tfc-sales-bu-stack

3. **GitHub Teams Created**:
   - finance-admins
   - engineering-admins
   - sales-admins

4. **Stack Outputs Available**:
   Check outputs in HCP Terraform UI for each deployment.

## Published Outputs

Outputs from `outputs.tfcomponent.hcl` are automatically published for downstream BU Stacks:

| Output | Description |
|--------|-------------|
| `bu_infrastructure` | Complete infrastructure mapping per BU |
| `bu_project_ids_map` | Map of BU names to project IDs |
| `bu_admin_tokens` | Map of BU names to admin tokens (sensitive) |
| `bu_stack_repo_names` | Map of BU names to GitHub repo names |
| `deployment_summary` | Resource creation summary |

BU Stacks consume these via `upstream_input`:

```hcl
# In BU Stack deployments.tfdeploy.hcl
upstream_input "platform_stack" {
  type   = "stack"
  source = "app.terraform.io/cloudbrokeraz/Platform_Team/platform-stack"
}

deployment "dev" {
  inputs = {
    bu_project_id  = upstream_input.platform_stack.bu_project_ids_map["finance"]
    bu_admin_token = upstream_input.platform_stack.bu_admin_tokens["finance"]
    # ...
  }
}
```

## Adding a New Business Unit

1. **Create YAML config**: `config/<new_bu>.yaml`
2. **Add deployment block** in `deployments.tfdeploy.hcl`
3. **Commit and push** to main branch
4. **Plan and apply** new deployment

Example:
```hcl
deployment "marketing" {
  inputs = {
    tfc_organization_name = local.organization
    business_unit         = "marketing"
    tfe_identity_token    = identity_token.tfe.jwt
    github_token          = identity_token.github.jwt
    # ... (same as other deployments)
  }
}
```

## Modifying BU Configuration

To update BU infrastructure (add consumer projects, modify settings):

1. **Edit YAML file**: `config/<bu_name>.yaml`
2. **Commit and push**
3. **Review plan** in HCP Terraform UI
4. **Apply** changes

Changes will update:
- Consumer projects
- Variable sets
- Project settings

**Note**: GitHub repository updates require code changes to `github.tf` in platform-onboarding module.

## Troubleshooting

### "Module not found in registry"
**Cause**: platform-onboarding module not published to PMR  
**Fix**: Publish module with git tag, verify in HCP Terraform Registry

### "Failed to authenticate with OIDC"
**Cause**: OIDC trust policy not configured or wrong audience  
**Fix**: Verify audience is `platform.onboarding` in cloud provider trust policy

### "Repository already exists"
**Cause**: GitHub repo with same name exists  
**Fix**: Delete existing repo or change `bu_stack_repo_prefix`/`suffix` in deployments.tfdeploy.hcl

### "Insufficient GitHub permissions"
**Cause**: GitHub token missing `admin:org` scope  
**Fix**: Regenerate PAT with correct scopes

### "YAML parsing error"
**Cause**: Invalid YAML syntax in config files  
**Fix**: Validate with `yamllint config/*.yaml`

## CI/CD

This Stack uses HCP Terraform's native VCS integration:
- **Pull Requests**: Speculative plans automatically run
- **Main Branch**: Plans trigger on push (manual apply)
- **Auto-Apply**: Disabled (requires manual approval)

Optional: Add GitHub Actions for additional validation:
```yaml
name: Validate Stack
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.13.5
      - run: terraform stacks validate
      - run: yamllint config/*.yaml
```

## Related Resources

- **platform-onboarding Module**: `app.terraform.io/cloudbrokeraz/platform-onboarding/tfe`
- **bu-onboarding Module**: `app.terraform.io/cloudbrokeraz/bu-onboarding/tfe`
- **BU Stack Repositories**: Auto-created by this Stack
- **Documentation**: See `/docs` for OIDC setup and BU onboarding guides

## Support

Platform Team - `platform-team@cloudbrokeraz.com`

---

**Stack Version**: 1.0.0  
**Organization**: cloudbrokeraz  
**Project**: Platform_Team  
**Last Updated**: November 2024
