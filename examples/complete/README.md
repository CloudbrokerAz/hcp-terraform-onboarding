# Complete Example - Multi-Business Unit Enterprise Onboarding

This example demonstrates a full-featured enterprise deployment with multiple business units, custom RBAC, SSO integration, and advanced variable set management.

## What This Example Creates

### Platform Team Layer (tenant-config-project)
- **3 Business Units:** Finance, Engineering, Marketing
- **9 Projects:** 3 per BU (development, staging, production)
- **3 BU Admin Teams** with SSO integration
- **3 BU Control Projects** with workspace management
- **Variable Sets** with team tokens and BU-specific configurations
- **Custom RBAC** with read, write, and admin access levels

### BU Team Layers (bu-control-workspace)
- **12+ Workspaces** across all BUs
- **GitHub Repositories** with VCS connections
- **Environment-specific** variable sets (dev, staging, prod)
- **Remote State Sharing** between related workspaces
- **Custom Execution** modes (agent pools for sensitive workspaces)

## Architecture Overview

```
Platform Team (tenant-config-project)
├── Finance BU
│   ├── finance_admin team
│   ├── finance_control project
│   │   └── finance_workspace_control workspace
│   └── Consumer Projects
│       ├── finance_app-dev
│       ├── finance_app-staging
│       └── finance_app-production
│
├── Engineering BU
│   ├── engineering_admin team
│   ├── engineering_control project
│   │   └── engineering_workspace_control workspace
│   └── Consumer Projects
│       ├── engineering_platform-dev
│       ├── engineering_platform-staging
│       └── engineering_platform-production
│
└── Marketing BU
    ├── marketing_admin team
    ├── marketing_control project
    │   └── marketing_workspace_control workspace
    └── Consumer Projects
        ├── marketing_web-dev
        ├── marketing_web-staging
        └── marketing_web-production

Each BU Control Workspace
├── Multiple workspaces (web, api, database, etc.)
├── GitHub repositories with VCS
├── Variable sets (environment-specific)
└── RBAC configurations
```

## Prerequisites

1. **HCP Terraform Organization** with enterprise features
2. **SSO Provider** configured (optional but recommended)
3. **GitHub Organization** with OAuth configured
4. **Agent Pools** configured (optional, for secure execution)
5. **Platform Team Credentials** with organization admin access
6. **Template Repository** available

## Usage

### Step 1: Deploy Platform Team Infrastructure

```bash
cd tenant-config-project
```

Create `terraform.tfvars`:
```hcl
tfc_organization_name = "your-enterprise-org"
business_unit         = "all"  # Special value to process all BUs
```

Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

**Expected Duration:** 3-5 minutes

**Expected Output:**
```
projects = {
  "finance_app-dev" = {
    bu = "finance"
    project_id = "prj-xxxxxxxxxxxxx"
    # ... additional attributes
  }
  # ... 8 more projects
}
```

### Step 2: Retrieve BU Admin Tokens

The platform team deployment creates variable sets containing BU admin tokens. Extract these for each BU:

```bash
# Finance BU project IDs
terraform output -json projects | jq -r 'with_entries(select(.key | startswith("finance"))) | to_entries | map({(.key): .value.project_id}) | add'

# Engineering BU project IDs
terraform output -json projects | jq -r 'with_entries(select(.key | startswith("engineering"))) | to_entries | map({(.key): .value.project_id}) | add'

# Marketing BU project IDs
terraform output -json projects | jq -r 'with_entries(select(.key | startswith("marketing"))) | to_entries | map({(.key): .value.project_id}) | add'
```

### Step 3: Deploy Finance BU Workspaces

```bash
cd ../../bu-control-workspace-finance
```

Create `terraform.tfvars`:
```hcl
organization     = "your-enterprise-org"
github_org       = "your-github-org"
github_org_owner = "your-github-org"
oauth_token_id   = "ot-xxxxxxxxxxxxx"
bu_projects      = "{\"app-dev\":\"prj-aaa\",\"app-staging\":\"prj-bbb\",\"app-production\":\"prj-ccc\"}"
```

Deploy:
```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Deploy Engineering BU Workspaces

```bash
cd ../bu-control-workspace-engineering
```

Create `terraform.tfvars` (similar to Finance) and deploy.

### Step 5: Deploy Marketing BU Workspaces

```bash
cd ../bu-control-workspace-marketing
```

Create `terraform.tfvars` (similar to Finance) and deploy.

## Configuration Files

### Platform Team YAML Structure

Three YAML files in `tenant-config-project/config/`:
- `finance.yaml` - Finance BU configuration
- `engineering.yaml` - Engineering BU configuration
- `marketing.yaml` - Marketing BU configuration

Each defines:
- SSO team integration
- Multiple projects per environment
- Custom team access levels
- Project-level variable sets

### BU Team YAML Structure

Each BU has multiple workspace YAML files:
- Web application workspaces
- API service workspaces
- Database infrastructure workspaces
- Shared services workspaces

Features demonstrated:
- Remote state sharing
- Custom agent pools
- Environment-specific variables
- Auto-apply for development
- Manual approval for production

## Advanced Features

### 1. SSO Integration

Each BU team is linked to an SSO group:

```yaml
bu: finance
team:
  sso_team_id: "team-xxxxxxxxxxxxx"
```

Users are automatically added/removed based on SSO group membership.

### 2. Custom RBAC

Projects include custom team access configurations:

```yaml
custom_team_project_access:
  finance_readonly:
    access: "custom"
    project_access:
      settings: "read"
      teams: "read"
    workspace_access:
      state_versions: "read-outputs"
      runs: "read"
      variables: "none"
```

### 3. Remote State Sharing

Workspaces can share state outputs:

```yaml
remote_state: true
remote_state_consumers:
  - "finance-api-service"
  - "finance-web-app"
```

### 4. Agent Pool Execution

Sensitive workspaces use private agent pools:

```yaml
workspace_agents: true
execution_mode: "agent"
agent_pool_name: "finance-secure-pool"
```

### 5. Environment Promotion

Variables support environment-based values:

```yaml
variables:
  replicas:
    value: "1"  # dev
    # staging overrides to "3"
    # production overrides to "5"
```

## Validation

Verify all resources were created:

```bash
# Platform team resources
cd tenant-config-project
terraform output -json | jq '.projects.value | length'  # Should be 9

# Finance workspaces
cd ../bu-control-workspace-finance
terraform output -json | jq '.workspace_names.value | length'  # Should be 4+

# Engineering workspaces
cd ../bu-control-workspace-engineering
terraform output -json | jq '.workspace_names.value | length'  # Should be 4+

# Marketing workspaces
cd ../bu-control-workspace-marketing
terraform output -json | jq '.workspace_names.value | length'  # Should be 4+
```

## Expected Results

After full deployment:

### HCP Terraform Organization
- 3 BU admin teams with SSO
- 9 consumer projects (3 per BU)
- 3 BU control projects
- 12+ workspaces connected to VCS
- 20+ variable sets applied
- Complete RBAC structure

### GitHub Organization
- 12+ repositories from template
- VCS webhooks configured
- Branch protection rules (optional)

### Access Control
- BU admins manage their own workspaces
- Cross-BU state sharing where configured
- Environment-based approval workflows
- Segregated agent pool execution

## Cleanup

Remove resources in reverse order to avoid dependency issues:

```bash
# 1. Remove all BU workspaces (in any order)
cd bu-control-workspace-finance && terraform destroy
cd ../bu-control-workspace-engineering && terraform destroy
cd ../bu-control-workspace-marketing && terraform destroy

# 2. Remove platform infrastructure
cd ../tenant-config-project && terraform destroy
```

**Warning:** This will destroy all workspaces, projects, and teams. Ensure you have backups of any state files.

## Scaling Considerations

### Adding New Business Units

1. Create new YAML file in `tenant-config-project/config/`
2. Run `terraform plan` in tenant-config-project
3. Create new bu-control-workspace directory
4. Deploy BU-specific workspaces

### Adding New Projects to Existing BU

1. Update BU's YAML file with new project
2. Run `terraform apply` in tenant-config-project
3. Update bu-control-workspace tfvars with new project ID
4. Create workspace YAML files
5. Run `terraform apply` in bu-control-workspace

### Adding New Workspaces

1. Create new workspace YAML in `config/`
2. Run `terraform apply` in bu-control-workspace
3. No changes needed in platform layer

## Troubleshooting

### Issue: "Insufficient permissions"
**Solution:** Verify platform team credentials have organization admin access.

### Issue: "SSO team not found"
**Solution:** Ensure SSO team ID is correct. Find it in HCP Terraform under Settings > Teams > [Team Name] > SSO.

### Issue: "Project already exists"
**Solution:** Project names must be unique org-wide. Prefix with BU name (e.g., `finance_app-dev`).

### Issue: "Agent pool not found"
**Solution:** Create agent pools before deploying workspaces that reference them. Agent pools must exist in the organization.

### Issue: "Remote state consumer not found"
**Solution:** Ensure consumer workspace exists before configuring remote state sharing. Deploy in dependency order.

### Issue: "Variable set conflict"
**Solution:** Variable set names must be unique org-wide. Use BU prefix (e.g., `finance_app-dev_vars`).

## Security Best Practices

1. **Use SSO Integration** - Centralize user management
2. **Implement Agent Pools** - Keep sensitive credentials out of Terraform Cloud
3. **Enable Remote State Encryption** - Use customer-managed keys
4. **Rotate BU Admin Tokens** - Regularly regenerate team tokens
5. **Audit Access Logs** - Monitor project and workspace access
6. **Use Branch Protection** - Require PR reviews for production changes
7. **Enable Run Tasks** - Integrate security scanning and compliance checks

## Performance Optimization

- **Parallel BU Deployments** - Deploy BU control workspaces in parallel
- **Workspace Batching** - Group workspace creation in YAML files
- **State Locking** - Use consistent backend configuration
- **Remote Operations** - Leverage Terraform Cloud's parallelization

## Next Steps

- Configure [run tasks](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-tasks) for policy enforcement
- Set up [notifications](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/notifications) for workspace events
- Implement [workspace-level RBAC](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/permissions)
- Create [policy sets](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement) with Sentinel or OPA
- Configure [cost estimation](https://developer.hashicorp.com/terraform/cloud-docs/cost-estimation) for cloud resources

## Reference Documentation

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [VCS Integration Guide](https://developer.hashicorp.com/terraform/cloud-docs/vcs)
- [RBAC Documentation](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/permissions)
- [Agent Pools Documentation](https://developer.hashicorp.com/terraform/cloud-docs/agents)
- [Variable Sets Documentation](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables/managing-variables#variable-sets)
