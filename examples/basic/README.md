# Basic Example - Single Business Unit Onboarding

This example demonstrates the minimal configuration needed to onboard a single business unit to HCP Terraform using the platform team pattern.

## What This Example Creates

### Platform Team Layer (tenant-config-project)
- 1 Business Unit admin team (`finance_admin`)
- 1 BU control project (`finance_control`)
- 1 BU control workspace (`finance_workspace_control`)
- 1 Consumer project for the BU (`finance_app-dev`)
- Variable sets with BU admin tokens
- RBAC assignments

### BU Team Layer (bu-control-workspace)
- 2 Workspaces (`finance-web-app`, `finance-api-service`)
- 2 GitHub repositories (from template)
- VCS connections for GitOps workflows
- Variable sets for workspace configuration

## Prerequisites

1. HCP Terraform organization
2. GitHub organization with OAuth configured
3. Platform team credentials (TFC organization token)
4. Template repository available: `hashi-demo-lab/tf-template`

## Usage

### Step 1: Configure Platform Team Layer

```bash
cd tenant-config-project
```

Create `terraform.tfvars`:
```hcl
tfc_organization_name = "your-org-name"
business_unit         = "finance"
```

Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

**Expected Output:**
- `projects` - Map of created consumer projects
- `projects_project_access` - Access configuration details

### Step 2: Retrieve BU Admin Token

After platform team deployment completes, the BU admin token is stored in the variable set. The BU team will use this token to deploy their workspaces.

**Note:** In a production scenario, the platform team would securely share this token with the BU team through a secure channel (e.g., vault, encrypted communication).

### Step 3: Configure BU Team Layer

```bash
cd ../../bu-control-workspace
```

Create `terraform.tfvars`:
```hcl
organization     = "your-org-name"
github_org       = "your-github-org"
github_org_owner = "your-github-org"
oauth_token_id   = "ot-xxxxxxxxxxxxx"  # From OAuth setup
bu_projects      = "{\"app-dev\":\"prj-xxxxxxxxxxxxx\"}"  # From Step 1 output
```

**Important:** The `bu_projects` value comes from the `projects` output of the platform team layer. It maps project names to TFC project IDs.

Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

**Expected Output:**
- `varsetMap` - Variable set mappings
- `variable_set` - Created variable sets
- `project_id` - Map of workspace IDs
- `bu_projects` - Project ID mappings

## Configuration Files

### Platform Team YAML (`tenant-config-project/config/finance.yaml`)

```yaml
bu: finance
team:
  # Optional: SSO team ID if using SSO
  # sso_team_id: "team-xxxxxxxxxxxxx"

projects:
  app-dev:
    description: "Finance application development project"
    team_project_access:
      finance_developers:
        access: "write"
    var_sets:
      variables:
        environment:
          value: "development"
          category: "terraform"
          description: "Environment name"
```

### BU Team YAML (`bu-control-workspace/config/finance-workspaces.yaml`)

```yaml
organization: "your-org-name"
workspace_name: "finance-web-app"
project_name: "app-dev"
workspace_description: "Finance web application workspace"
workspace_terraform_version: "1.6.0"
workspace_tags: ["finance", "web", "production"]
workspace_auto_apply: false
create_repo: true

github:
  github_org: "your-github-org"
  github_org_owner: "your-github-org"
  github_repo_name: "finance-web-app"
  github_repo_desc: "Finance web application infrastructure"
  github_repo_visibility: "private"
  github_template_owner: "hashi-demo-lab"
  github_template_repo: "tf-template"

vcs_repo:
  identifier: "your-github-org/finance-web-app"
  oauth_token_id: "ot-xxxxxxxxxxxxx"

variables:
  app_name:
    value: "finance-web"
    category: "terraform"
    description: "Application name"

create_variable_set: true
var_sets:
  - variable_set_name: "finance-web-vars"
    variable_set_description: "Finance web app variables"
    global: false
    tags: ["finance", "web"]
    variables:
      region:
        value: "us-east-1"
        category: "terraform"
        description: "AWS region"
```

## Expected Results

After both deployments complete:

1. **In HCP Terraform:**
   - Finance control project with admin team access
   - Finance app-dev project with developer team access
   - 2 workspaces connected to GitHub repositories
   - Variable sets applied to workspaces

2. **In GitHub:**
   - 2 new repositories created from template
   - VCS webhooks configured for GitOps

3. **Access Control:**
   - Finance admins can manage their control workspace
   - Finance admins have tokens to provision additional workspaces
   - Developer teams have appropriate project access

## Validation

Verify the deployment:

```bash
# Check platform team resources
cd tenant-config-project
terraform output projects

# Check BU team resources
cd ../bu-control-workspace
terraform output project_id
```

## Cleanup

Remove resources in reverse order:

```bash
# 1. Remove BU workspaces
cd bu-control-workspace
terraform destroy

# 2. Remove platform infrastructure
cd ../tenant-config-project
terraform destroy
```

**Note:** GitHub repositories are not automatically deleted. Remove them manually if needed.

## Next Steps

- Review the [complete example](../complete/) for multi-BU scenarios
- Explore advanced features like custom RBAC and variable set inheritance
- Set up CI/CD pipelines for automated workspace provisioning
- Integrate with your organization's SSO provider

## Troubleshooting

### Issue: "Project ID not found"
**Solution:** Ensure you copied the correct project ID from the platform team output. The format should be `prj-xxxxxxxxxxxxx`.

### Issue: "OAuth token invalid"
**Solution:** Verify the OAuth token ID is correct and has access to your GitHub organization. Format should be `ot-xxxxxxxxxxxxx`.

### Issue: "GitHub template not found"
**Solution:** Ensure the template repository exists and is accessible. Default is `hashi-demo-lab/tf-template` (public).

### Issue: "Workspace already exists"
**Solution:** Workspace names must be unique within the organization. Change the `workspace_name` in your YAML config.

For more troubleshooting help, see the [workflow troubleshooting guide](../../.github/WORKFLOW-TROUBLESHOOTING.md).
