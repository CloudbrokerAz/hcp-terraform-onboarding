# HCP Terraform Platform Team Onboarding Module

A comprehensive Terraform-based solution for implementing a **platform team onboarding pattern** in HCP Terraform (Terraform Cloud). This module demonstrates enterprise-grade practices for:

- **Business Unit (BU) Segregation** - Isolated control planes per BU with dedicated admin teams
- **Project-Based Organization** - Structured workspace management using TFC projects
- **YAML-Driven Configuration** - Declarative workspace provisioning via configuration files
- **Automated GitHub Integration** - Repository creation from templates with VCS connections
- **RBAC and Variable Sets** - Team-based access control and environment-specific variables
- **Scalable Multi-Tenant Patterns** - Platform team manages infrastructure while BU teams self-service

## 🏗️ Architecture Overview

This module implements a **two-tier platform team pattern**:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Platform Team Layer                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  tenant-config-project/                                   │  │
│  │  - Creates BU admin teams                                 │  │
│  │  - Provisions BU control projects                         │  │
│  │  - Delegates project access to BU teams                   │  │
│  │  - Provides BU admin tokens via variable sets             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Business Unit Team Layer                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  bu-control-workspace/                                    │  │
│  │  - YAML-driven workspace provisioning                     │  │
│  │  - GitHub repository creation                             │  │
│  │  - Workspace-to-VCS connections                           │  │
│  │  - Variable set associations                              │  │
│  │  - Team access assignments                                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Concepts

**Platform Team Responsibilities:**
- Create and manage business unit admin teams
- Provision control projects for each BU
- Generate and distribute BU admin team tokens
- Maintain organization-level policies and standards

**Business Unit Team Responsibilities:**
- Define workspace requirements in YAML configuration
- Provision workspaces within their control project
- Manage application-specific variables and settings
- Control access within their project scope

## ✨ Features

- ✅ **Business Unit Isolation** - Dedicated teams, projects, and workspaces per BU
- ✅ **YAML Configuration** - Define workspaces declaratively with version-controlled configs
- ✅ **GitHub Automation** - Auto-create repos from templates with branch protection
- ✅ **Variable Set Management** - Centralized and workspace-specific variable management
- ✅ **RBAC Integration** - Team-based workspace access (read, plan, write, admin)
- ✅ **VCS Integration** - Automated workspace-to-repository connections
- ✅ **Remote State Sharing** - Cross-workspace state access configuration
- ✅ **Agent Pool Support** - Self-hosted agent configuration per workspace
- ✅ **Assessment Mode** - Optional drift detection and compliance checks

## 📋 Prerequisites

Before using this module, ensure you have:

1. **HCP Terraform Organization** - Active organization with appropriate permissions
2. **GitHub Organization** - For repository creation (optional but recommended)
3. **OAuth Token** - GitHub VCS connection configured in TFC
4. **Terraform CLI** - Version 1.6+ installed locally
5. **API Token** - TFC team or user token with admin permissions

### Required Permissions

**Platform Team Token (for tenant-config-project):**
- Organization: Manage Projects
- Organization: Manage Teams
- Organization: Manage Variable Sets

**BU Admin Token (for bu-control-workspace):**
- Project: Admin access to BU control project
- Ability to create workspaces
- Ability to manage workspace variables

## 🚀 Quick Start

### Step 1: Platform Team - Create BU Infrastructure

```hcl
# Platform team provisions BU admin teams and projects
cd tenant-config-project

terraform init
terraform plan
terraform apply
```

This creates:
- BU admin team (e.g., `strategy_admin`)
- BU control project (e.g., `strategy_control`)
- BU control workspace
- Variable set with BU admin token
- Team access assignments

### Step 2: BU Team - Define Workspaces in YAML

Create a workspace configuration file in `bu-control-workspace/config/`:

```yaml
# config/my-app.yaml
workspace_name: "my-application-prod"
workspace_description: "Production environment for my application"
project_name: "strategy_applications"
create_project: false
project_id: "prj-abc123"  # From platform team output

workspace_terraform_version: "1.6.0"
workspace_tags: ["production", "application"]
workspace_auto_apply: false

# GitHub repository creation
create_repo: true
github:
  github_repo_name: "my-application-infra"
  github_repo_desc: "Terraform infrastructure for my application"
  github_repo_visibility: "private"
  github_template_repo: "tf-template"

# VCS integration
vcs_repo:
  identifier: "my-org/my-application-infra"
  branch: "main"
  ingress_submodules: false

# Variables
variables:
  environment:
    value: "production"
    category: "terraform"
    description: "Environment name"
  
  AWS_REGION:
    value: "us-east-1"
    category: "env"
    description: "Default AWS region"
    sensitive: false

# Team access
workspace_read_access_emails: ["viewer@company.com"]
workspace_plan_access_emails: ["developer@company.com"]
workspace_write_access_emails: ["admin@company.com"]
```

### Step 3: BU Team - Provision Workspaces

```hcl
# BU team provisions their workspaces from YAML
cd bu-control-workspace

terraform init
terraform plan
terraform apply
```

This creates:
- GitHub repository (if `create_repo: true`)
- TFC workspace with specified configuration
- VCS connection to GitHub repository
- Workspace variables
- Team access assignments
- Variable set associations

## 📂 Module Structure

```
hcp-terraform-onboarding/
├── tenant-config-project/          # Platform team layer
│   ├── main.tf                     # BU team and project creation
│   ├── variables.tf                # Organization-level inputs
│   ├── outputs.tf                  # BU admin tokens and project IDs
│   ├── locals.tf                   # YAML processing logic
│   └── config/                     # BU definitions
│       └── *.yaml                  # Business unit configurations
│
├── bu-control-workspace/           # BU team layer
│   ├── main.tf                     # Workspace provisioning logic
│   ├── variables.tf                # BU-level inputs
│   ├── outputs.tf                  # Workspace IDs and details
│   ├── providers.tf                # TFE provider configuration
│   └── config/                     # Workspace definitions
│       └── *.yaml                  # Workspace configurations
│
└── examples/                       # Usage examples
    ├── basic/                      # Minimal setup
    └── complete/                   # Full-featured demo
```

## 🔧 Configuration

### Tenant Configuration (Platform Team)

```yaml
# tenant-config-project/config/business-unit.yaml
bu: "strategy"
description: "Strategy and Architecture team"

# Optional: SSO team integration
team:
  sso_team_id: "team_abc123"

# Projects to create within this BU
projects:
  applications:
    description: "Application workspaces"
    team_project_access:
      developers:
        access: "write"
      viewers:
        access: "read"
    
    # Optional: Project-level variable sets
    var_sets:
      variables:
        ENVIRONMENT:
          value: "production"
          category: "env"
          description: "Environment tier"
```

### Workspace Configuration (BU Team)

```yaml
# bu-control-workspace/config/workspace.yaml
workspace_name: "my-workspace"
workspace_description: "Description of workspace purpose"
project_name: "strategy_applications"
workspace_terraform_version: "1.6.0"
workspace_tags: ["tag1", "tag2"]

# Workspace behavior
workspace_auto_apply: false
queue_all_runs: false
assessments_enabled: true

# VCS settings
file_triggers_enabled: true
workspace_vcs_directory: "/"

# Remote state sharing
remote_state: true
remote_state_consumers: ["ws-abc123", "ws-def456"]

# Agent execution (optional)
workspace_agents: false
execution_mode: "remote"
agent_pool_name: null

# RBAC
workspace_read_access_emails: ["user@example.com"]
workspace_plan_access_emails: []
workspace_write_access_emails: []
```

## 📤 Outputs

### Platform Team Outputs (tenant-config-project)

- `bu_admin_team_ids` - Map of BU admin team IDs
- `bu_control_project_ids` - Map of BU control project IDs
- `bu_admin_workspace_ids` - Map of BU control workspace IDs
- `consumer_project_ids` - Map of all project IDs created for BUs
- `variable_set_ids` - Map of BU admin variable set IDs

### BU Team Outputs (bu-control-workspace)

- `workspace_ids` - Map of created workspace IDs
- `workspace_names` - List of workspace names
- `github_repositories` - Map of created GitHub repositories
- `variable_set_associations` - Variable set to workspace mappings

## 🧪 Testing

Run unit tests:

```bash
terraform test -filter=tests/unit-tests.tftest.hcl
```

Run integration tests:

```bash
terraform test -filter=tests/integration-tests.tftest.hcl
```

See [tests/README.md](tests/README.md) for detailed testing documentation.

## 🔐 Security Considerations

- **Token Management** - BU admin tokens are stored in variable sets (sensitive)
- **Least Privilege** - BU teams only have access to their control projects
- **State Isolation** - Each BU has separate state files
- **RBAC Enforcement** - Workspace access controlled via team assignments
- **VCS Security** - OAuth token securely managed in TFC
- **Audit Trail** - All changes tracked via Terraform state and TFC audit logs

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code standards and formatting
- Pre-commit hooks setup
- Testing requirements
- Pull request process

## 📄 License

This module is licensed under the [MIT License](LICENSE).

## 🆘 Support

For issues, questions, or contributions:
- **Issues** - [GitHub Issues](https://github.com/your-org/hcp-terraform-onboarding/issues)
- **Documentation** - See `examples/` and `docs/` directories
- **Community** - HashiCorp Community Forum

## 📚 Additional Resources

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HashiCorp Learn - TFC Projects](https://learn.hashicorp.com/tutorials/terraform/projects)
- [Platform Team Patterns](https://developer.hashicorp.com/well-architected-framework)

---

**Version**: 1.0.0  
**Last Updated**: November 2025  
**Maintained By**: Platform Engineering Team
