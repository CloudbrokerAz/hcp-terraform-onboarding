# Examples

This directory contains practical examples demonstrating how to use the HCP Terraform onboarding modules in different scenarios. Each example is a complete, working configuration that you can adapt to your needs.

## Available Examples

### 📁 [Basic Example](./basic/)
**Recommended for:** First-time users, POC deployments, single business unit onboarding

A minimal configuration for onboarding a single business unit (Finance) with two workspaces. This example demonstrates:
- Platform team layer deployment
- BU control workspace setup
- GitHub repository creation with VCS integration
- Basic variable sets and RBAC
- Simple project structure

**Time to deploy:** ~5-10 minutes  
**Resources created:** 1 BU, 1 project, 2 workspaces, 2 GitHub repos

[View Basic Example →](./basic/)

---

### 📁 [Complete Example](./complete/)
**Recommended for:** Enterprise deployments, multi-BU organizations, production use

A full-featured configuration for onboarding three business units (Finance, Engineering, Marketing) with environment separation and advanced features. This example demonstrates:
- Multi-BU platform infrastructure
- Environment-based projects (dev, staging, production)
- SSO team integration
- Custom RBAC configurations
- Remote state sharing between workspaces
- Agent pool execution for sensitive operations
- Environment-specific variable sets
- Production-grade security practices

**Time to deploy:** ~15-20 minutes  
**Resources created:** 3 BUs, 9 projects, 12+ workspaces, 12+ GitHub repos

[View Complete Example →](./complete/)

---

## Quick Comparison

| Feature | Basic Example | Complete Example |
|---------|--------------|------------------|
| **Business Units** | 1 (Finance) | 3 (Finance, Engineering, Marketing) |
| **Projects per BU** | 1 (app-dev) | 3 (dev, staging, production) |
| **Workspaces** | 2 | 12+ |
| **SSO Integration** | ❌ Optional | ✅ Included |
| **Environment Separation** | ❌ Single env | ✅ Dev/Staging/Prod |
| **Custom RBAC** | ⚠️ Basic | ✅ Advanced |
| **Remote State Sharing** | ⚠️ Simple | ✅ Complex |
| **Agent Pools** | ❌ Not used | ✅ Production workspaces |
| **Auto-apply** | ⚠️ Disabled | ✅ Dev: Yes, Prod: No |
| **Complexity** | 🟢 Low | 🟡 Medium |
| **Production Ready** | 🟡 Demo/POC | 🟢 Yes |

## Choosing an Example

### Start with Basic if:
- ✅ You're new to HCP Terraform onboarding patterns
- ✅ You have a single business unit to onboard
- ✅ You want a quick proof-of-concept
- ✅ Your organization has simple RBAC needs
- ✅ You don't need environment separation yet

### Use Complete if:
- ✅ You're deploying to production
- ✅ You have multiple business units
- ✅ You need environment isolation (dev/staging/prod)
- ✅ You use SSO for team management
- ✅ You require custom RBAC policies
- ✅ You need secure execution with agent pools
- ✅ You want to see all platform features

## Example Structure

Each example follows this structure:

```
examples/<example-name>/
├── README.md                          # Example documentation
├── tenant-config-project/             # Platform team layer
│   ├── main.tf                       # Module usage
│   ├── variables.tf                  # Input variables
│   ├── terraform.tfvars.example      # Configuration template
│   └── config/                       # BU YAML configurations
│       ├── finance.yaml
│       ├── engineering.yaml          # (Complete example only)
│       └── marketing.yaml            # (Complete example only)
│
└── bu-control-workspace(-<bu>)/       # BU team layer(s)
    ├── main.tf                       # Module usage
    ├── variables.tf                  # Input variables
    ├── terraform.tfvars.example      # Configuration template
    └── config/                       # Workspace YAML configs
        ├── <workspace-1>.yaml
        ├── <workspace-2>.yaml
        └── ...
```

## Getting Started

### Prerequisites

Before using any example, ensure you have:

1. **HCP Terraform Organization** 
   - Create at [app.terraform.io](https://app.terraform.io)
   - Note your organization name

2. **GitHub Organization**
   - Personal or organization account
   - OAuth application configured in HCP Terraform
   - Template repository accessible (default: `hashi-demo-lab/tf-template`)

3. **Authentication**
   - **Platform Team:** Organization or admin token
   - **BU Teams:** Team tokens (created by platform team)

4. **Local Tools**
   ```bash
   # Terraform CLI
   terraform --version  # >= 1.6.0 required
   
   # Git (for pre-commit hooks)
   git --version
   
   # Optional: Pre-commit framework
   pip install pre-commit
   ```

### Deployment Steps (General)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/CloudbrokerAz/hcp-terraform-onboarding.git
   cd hcp-terraform-onboarding/examples/<example-name>
   ```

2. **Deploy Platform Team Layer:**
   ```bash
   cd tenant-config-project
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform plan
   terraform apply
   ```

3. **Retrieve BU Project IDs:**
   ```bash
   terraform output -json | jq '.projects.value'
   # Copy project IDs for next step
   ```

4. **Deploy BU Control Workspace(s):**
   ```bash
   cd ../bu-control-workspace  # (or -finance, -engineering, etc.)
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values and project IDs
   terraform init
   terraform plan
   terraform apply
   ```

5. **Verify Deployment:**
   ```bash
   # Check HCP Terraform UI
   open https://app.terraform.io/app/<your-org>/workspaces
   
   # Check GitHub repositories
   open https://github.com/<your-org>
   ```

## Configuration Customization

### Modifying YAML Configurations

All infrastructure is defined via YAML files in `config/` directories. To customize:

#### Platform Team YAML (`tenant-config-project/config/<bu>.yaml`):
```yaml
bu: <business-unit-name>
team:
  sso_team_id: "team-xxxxx"  # Optional SSO integration
projects:
  <project-name>:
    description: "Project description"
    team_project_access: { }  # RBAC configuration
    var_sets: { }             # Project-level variables
```

#### BU Team YAML (`bu-control-workspace/config/<workspace>.yaml`):
```yaml
organization: "your-org"
workspace_name: "<unique-workspace-name>"
project_name: "<project-from-platform-team>"
create_repo: true
github: { }       # GitHub repository configuration
vcs_repo: { }     # VCS connection settings
variables: { }    # Workspace variables
var_sets: [ ]     # Variable sets
```

### Common Customizations

#### Change Workspace Count
Add or remove YAML files in `bu-control-workspace/config/`:
```bash
cp config/existing-workspace.yaml config/new-workspace.yaml
# Edit new-workspace.yaml
terraform apply
```

#### Add Business Unit
1. Create new YAML in `tenant-config-project/config/<new-bu>.yaml`
2. Apply platform team configuration
3. Create new `bu-control-workspace-<new-bu>/` directory
4. Copy configuration from existing BU
5. Update variables and apply

#### Change GitHub Organization
Update `terraform.tfvars`:
```hcl
github_org = "new-org-name"
github_org_owner = "new-org-owner"
```

#### Use Different Template Repository
Edit workspace YAML:
```yaml
github:
  github_template_owner: "your-org"
  github_template_repo: "your-template"
```

## Validation and Testing

### Pre-deployment Validation
```bash
# Validate Terraform syntax
terraform fmt -recursive -check
terraform validate

# Validate YAML syntax (requires Python)
python3 -c "import yaml; yaml.safe_load(open('config/example.yaml'))"

# Run pre-commit checks
pre-commit run --all-files
```

### Post-deployment Validation
```bash
# Platform team layer
cd tenant-config-project
terraform output -json | jq '.projects.value | length'  # Should match expected count

# BU team layer
cd ../bu-control-workspace
terraform output workspace_names  # List created workspaces

# Check HCP Terraform
tfe workspace list -organization="your-org"
```

## Troubleshooting

### Common Issues

#### Issue: "Module not found"
**Cause:** Relative path to root module incorrect  
**Solution:** Verify `source = "../../../<module-name>"` points correctly

#### Issue: "Project ID not found"
**Cause:** Incorrect or missing project ID in `bu_projects` variable  
**Solution:** Copy exact JSON output from platform team: `terraform output -raw <bu>_projects_json`

#### Issue: "OAuth token invalid"
**Cause:** Incorrect OAuth token ID or token expired  
**Solution:** 
1. Go to HCP Terraform → Settings → VCS Providers
2. Find your GitHub connection
3. Copy OAuth token ID (starts with `ot-`)
4. Update `terraform.tfvars`

#### Issue: "Workspace already exists"
**Cause:** Duplicate workspace name in organization  
**Solution:** Workspace names must be globally unique. Use BU prefix: `<bu>-<workspace-name>`

#### Issue: "GitHub repository already exists"
**Cause:** Repository name collision  
**Solution:** Change `github_repo_name` in workspace YAML or delete existing repo

### Getting Help

- **Workflow Issues:** See [Workflow Troubleshooting Guide](../.github/WORKFLOW-TROUBLESHOOTING.md)
- **Setup Issues:** See [Repository Setup Guide](../.github/REPOSITORY-SETUP.md)
- **Module Issues:** Check root [README.md](../README.md)
- **Report Bug:** [Open an issue](https://github.com/CloudbrokerAz/hcp-terraform-onboarding/issues)

## Best Practices

### 1. Version Control
- Commit YAML configurations to git
- Use branches for testing changes
- Tag stable configurations

### 2. Secrets Management
- **Never commit** OAuth tokens or credentials
- Use `.gitignore` for `terraform.tfvars`
- Store sensitive values in HCP Terraform variables
- Use environment variables for local development

### 3. Change Management
- Test changes in development environments first
- Use `terraform plan` to preview changes
- Enable speculative plans on pull requests
- Require PR reviews for production changes

### 4. State Management
- Use remote state backend (HCP Terraform)
- Lock state during operations
- Back up state files regularly
- Never manually edit state

### 5. RBAC
- Follow principle of least privilege
- Use SSO integration when possible
- Separate BU admin tokens per business unit
- Rotate team tokens regularly

### 6. Monitoring
- Enable HCP Terraform notifications
- Configure workspace run notifications
- Monitor GitHub webhook deliveries
- Track resource costs with cost estimation

## Next Steps

After deploying an example:

1. **Review Created Resources**
   - Explore HCP Terraform UI
   - Check GitHub repositories
   - Verify VCS connections

2. **Test GitOps Workflow**
   - Make a change in GitHub
   - Watch automatic plan trigger
   - Review and approve run

3. **Customize Configuration**
   - Modify YAML files for your needs
   - Add additional workspaces
   - Configure notifications

4. **Implement CI/CD**
   - Enable GitHub Actions workflows
   - Add policy enforcement
   - Configure run tasks

5. **Scale Your Deployment**
   - Add more business units
   - Create additional environments
   - Implement advanced RBAC

## Additional Resources

### Documentation
- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Module Documentation](https://developer.hashicorp.com/terraform/language/modules)
- [VCS Integration Guide](https://developer.hashicorp.com/terraform/cloud-docs/vcs)

### Tutorials
- [Get Started with HCP Terraform](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started)
- [Manage Permissions with Teams](https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-permissions)
- [Enforce Policy with Sentinel](https://developer.hashicorp.com/terraform/tutorials/policy)

### Related Modules
- [hashi-demo-lab/terraform-tfe-project-team](https://github.com/hashi-demo-lab/terraform-tfe-project-team)
- [hashi-demo-lab/terraform-tfe-onboarding-module](https://github.com/hashi-demo-lab/terraform-tfe-onboarding-module)
- [hashi-demo-lab/terraform-tfe-variable-sets](https://github.com/hashi-demo-lab/terraform-tfe-variable-sets)

## Contributing

Found an issue with an example or want to add a new one? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the example thoroughly
5. Submit a pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for detailed guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
