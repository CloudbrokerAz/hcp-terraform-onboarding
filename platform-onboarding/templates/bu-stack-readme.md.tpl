# ${bu_display_name} BU - Terraform Stack

This repository contains the Terraform Stack configuration for managing **${bu_display_name}** workspaces in HCP Terraform.

## Overview

This Stack is part of the **${organization}** HCP Terraform organization and automatically provisions workspaces based on YAML configuration files in the `configs/` directory.

**Architecture:**
- **Platform Stack**: `${platform_project}` project creates BU infrastructure
- **BU Stack** (this repo): Consumes platform outputs, manages workspaces per environment

## Features

- ✅ **YAML-Driven Workspace Provisioning** - Define workspaces in `configs/${bu_name}.yaml`
- ✅ **Multi-Environment Support** - Dev, Staging, Production deployments
- ✅ **Automatic VCS Integration** - Connects workspaces to GitHub repositories
- ✅ **Variable Set Management** - Centralized configuration management
- ✅ **Upstream Integration** - Consumes platform stack outputs automatically

## Repository Structure

```
${repo_name}/
├── variables.tfcomponent.hcl       # Stack input variables
├── providers.tfcomponent.hcl        # Provider configurations (TFE with OIDC)
├── components.tfcomponent.hcl       # Component definitions
├── outputs.tfcomponent.hcl          # Stack outputs
├── deployments.tfdeploy.hcl         # Deployment configurations (dev/staging/prod)
├── configs/
│   └── ${bu_name}.yaml              # Workspace definitions
└── .github/
    └── workflows/
        └── terraform-stacks.yml     # CI/CD workflow
```

## Getting Started

### Prerequisites

1. **HCP Terraform Account**: Access to `${organization}` organization
2. **BU Admin Permissions**: Member of `${bu_name}_admin` team
3. **Terraform CLI**: Version 1.13.5 or later
4. **GitHub Access**: Clone permission for this repository

### Quick Start

1. **Clone this repository**:
   ```bash
   git clone git@github.com:${github_org}/${repo_name}.git
   cd ${repo_name}
   ```

2. **Review example configuration**:
   ```bash
   cat configs/${bu_name}.yaml
   ```

3. **Add your workspaces**: Edit `configs/${bu_name}.yaml` to define your infrastructure workspaces

4. **Commit and push**:
   ```bash
   git add configs/${bu_name}.yaml
   git commit -m "Add new workspace configurations"
   git push origin main
   ```

5. **HCP Terraform automatically triggers**: Plans run automatically on push to main branch

## Workspace Configuration

Define workspaces in `configs/${bu_name}.yaml`:

```yaml
business_unit: ${bu_name}
projects:
  - name: my-application
    var_sets:
      variables:
        - key: environment
          value: production
          category: terraform
    workspaces:
      - name: my-app-frontend
        description: Frontend application infrastructure
        terraform_version: "1.9.0"
        working_directory: "terraform/frontend"
        trigger_prefixes:
          - "terraform/frontend/"
        vcs_repo:
          identifier: "${github_org}/my-app-frontend"
          branch: "main"
        
      - name: my-app-backend
        description: Backend API infrastructure
        terraform_version: "1.9.0"
        working_directory: "terraform/backend"
        trigger_prefixes:
          - "terraform/backend/"
        vcs_repo:
          identifier: "${github_org}/my-app-backend"
          branch: "main"
```

## Deployments

This Stack has **three deployments**:

| Deployment | Description | HCP Terraform Project |
|------------|-------------|----------------------|
| **dev** | Development environment | `BU_${bu_name}` |
| **staging** | Staging environment | `BU_${bu_name}` |
| **production** | Production environment | `BU_${bu_name}` |

Each deployment creates isolated workspaces based on the YAML configuration.

## OIDC Authentication

This Stack uses **OIDC authentication** with HCP Terraform:

- **Audience**: `${bu_name}-team-*`
- **Trust Policy**: Configured in AWS/Azure/GCP for this BU
- **Scoping**: Wildcard allows dev/staging/prod deployments with different roles

## CI/CD Workflow

GitHub Actions automatically:
1. ✅ Validates Stack configuration on pull requests
2. ✅ Plans changes on push to main
3. ✅ Requires manual approval for apply (in HCP Terraform UI)

## Making Changes

### Adding a New Workspace

1. Edit `configs/${bu_name}.yaml`
2. Add workspace definition under the appropriate project
3. Commit and push changes
4. Review plan in HCP Terraform
5. Apply changes in HCP Terraform UI

### Modifying Existing Workspaces

1. Update workspace properties in `configs/${bu_name}.yaml`
2. Commit and push changes
3. Review plan in HCP Terraform (shows updates)
4. Apply changes

### Removing a Workspace

1. Remove workspace entry from `configs/${bu_name}.yaml`
2. Commit and push changes
3. Review plan in HCP Terraform (shows deletions)
4. Apply changes (workspace will be destroyed)

## Troubleshooting

### "Invalid deployment configuration"

- **Cause**: Syntax error in `.tfdeploy.hcl`
- **Fix**: Run `terraform stacks validate` locally to identify issues

### "Failed to authenticate with OIDC"

- **Cause**: Trust policy not configured correctly
- **Fix**: Verify OIDC audience matches `${bu_name}-team-*` in cloud provider trust policy

### "Upstream input not found"

- **Cause**: Platform stack not deployed or outputs not published
- **Fix**: Verify platform stack deployment in `${platform_project}` project

### "Workspace already exists"

- **Cause**: Workspace name collision
- **Fix**: Ensure workspace names are unique across all YAML configs

## Support

- **Platform Team**: Contact via Slack `#platform-team`
- **Documentation**: [HCP Terraform Stacks Guide](https://developer.hashicorp.com/terraform/language/stacks)
- **Issues**: Open GitHub issue in this repository

## Related Resources

- **Platform Stack**: `${github_org}/tfc-platform-stack`
- **Module Source**: `app.terraform.io/${organization}/bu-onboarding/tfe`
- **HCP Terraform UI**: https://app.terraform.io/app/${organization}

---

**Managed by**: ${bu_display_name} BU Admin Team  
**Stack Version**: 1.0.0  
**Last Updated**: $(date +%Y-%m-%d)
