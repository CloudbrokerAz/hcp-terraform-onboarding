# HCP Terraform Platform Team Onboarding Module

A comprehensive Terraform-based solution for implementing a **platform team onboarding pattern** in HCP Terraform (Terraform Cloud). This module demonstrates enterprise-grade practices for:

- **Business Unit (BU) Segregation** - Isolated control planes per BU with dedicated admin teams
- **Project-Based Organization** - Structured workspace management using TFC projects
- **YAML-Driven Configuration** - Declarative workspace provisioning via configuration files
- **Automated GitHub Integration** - Repository creation from templates with VCS connections
- **RBAC and Variable Sets** - Team-based access control and environment-specific variables
- **Scalable Multi-Tenant Patterns** - Platform team manages infrastructure while BU teams self-service

---

## � Getting Started

### New to This Pattern?

**Start here**: [QUICK-START.md](QUICK-START.md) - Get running in 15 minutes!

### Have Questions?

**Read this**: [QUESTIONS-ANSWERED.md](QUESTIONS-ANSWERED.md) - Answers about PMR publishing and bootstrap workspace

### Need Complete Setup?

**Follow this**: [SETUP-GUIDE.md](SETUP-GUIDE.md) - Production deployment guide

---

## 📚 Complete Documentation

| Guide | Purpose | When to Use |
|-------|---------|-------------|
| **[QUICK-START.md](QUICK-START.md)** | 15-minute getting started | First time setup |
| **[QUESTIONS-ANSWERED.md](QUESTIONS-ANSWERED.md)** | PMR & bootstrap answers | Understanding the pattern |
| **[SETUP-GUIDE.md](SETUP-GUIDE.md)** | Complete production setup | Detailed configuration |
| **[BOOTSTRAP-PATTERN.md](BOOTSTRAP-PATTERN.md)** | Bootstrap workspace pattern | Understanding architecture |
| **[ARCHITECTURE-DIAGRAMS.md](ARCHITECTURE-DIAGRAMS.md)** | Visual architecture diagrams | Visual learners |
| **[DEMO-GUIDE.md](DEMO-GUIDE.md)** | Step-by-step demo walkthrough | Demonstrating to stakeholders |
| **[REPOSITORY-SETUP.md](.github/REPOSITORY-SETUP.md)** | Repository configuration | Git and VCS setup |
| **[WORKFLOW-TROUBLESHOOTING.md](.github/WORKFLOW-TROUBLESHOOTING.md)** | CI/CD troubleshooting | Debugging workflow issues |

---

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

| Output | Type | Description |
|--------|------|-------------|
| `bu_admin_team_ids` | map(string) | Map of BU admin team IDs indexed by business unit name |
| `bu_admin_team_names` | map(string) | Map of BU admin team names indexed by business unit name |
| `bu_control_project_ids` | map(string) | Map of BU control project IDs containing BU control workspaces |
| `bu_control_project_names` | map(string) | Map of BU control project names indexed by business unit |
| `bu_control_workspace_ids` | map(string) | Map of BU control workspace IDs that manage BU infrastructure |
| `bu_control_workspace_names` | map(string) | Map of BU control workspace names indexed by business unit |
| `consumer_projects` | map(object) | Complete map of all consumer projects with full configuration |
| `consumer_project_ids` | map(string) | Map of consumer project IDs indexed by `{bu}_{project}` key |
| `consumer_project_names` | map(string) | Map of consumer project names indexed by `{bu}_{project}` key |
| `variable_set_ids` | map(string) | Map of BU admin variable set IDs containing tokens and project mappings |
| `variable_set_names` | map(string) | Map of variable set names indexed by business unit |
| `bu_projects_mappings` | map(string) | JSON-formatted project ID mappings for each BU |
| `bu_projects_access` | map(object) | Processed project access configuration from YAML |
| `business_units` | list(string) | List of all configured business units |
| `tenant_configuration` | map(object) | Complete tenant configuration derived from YAML files |

### BU Team Outputs (bu-control-workspace)

| Output | Type | Description |
|--------|------|-------------|
| `workspace_ids` | map(string) | Map of created workspace IDs indexed by workspace name |
| `workspace_names` | list(string) | List of all workspace names created by this module |
| `workspace_details` | map(object) | Complete workspace module output with all attributes |
| `github_repositories` | map(object) | Map of GitHub repository details (URLs, SSH/HTTP URLs) |
| `github_repository_urls` | map(string) | Map of GitHub repository HTML URLs for quick access |
| `variable_sets` | map(object) | Map of created variable set details (sensitive) |
| `variable_set_ids` | map(string) | Map of variable set IDs indexed by variable set name |
| `variable_set_workspace_associations` | map(object) | Shows which variable sets are associated with which workspaces |
| `varsetMap` | map(object) | Internal variable set mapping structure |
| `bu_projects` | string | JSON string of business unit project ID mappings from platform team |
| `bu_projects_decoded` | map(string) | Decoded project mappings as a map object |
| `workspace_configuration` | map(object) | Parsed workspace configuration from YAML files |
| `workspaces_with_repos` | list(string) | List of workspace names with GitHub repositories created |
| `workspaces_with_variable_sets` | list(string) | List of workspace names with variable sets configured |
| `all_workspace_ids_data` | map(string) | All workspace IDs in the organization (includes unmanaged) |

**Usage Examples:**

```hcl
# Reference platform team outputs
output "finance_project_id" {
  value = module.platform_team.consumer_project_ids["finance_applications"]
}

# Reference BU team outputs
output "app_workspace_url" {
  value = "https://app.terraform.io/app/${var.organization}/workspaces/${module.bu_workspaces.workspace_names[0]}"
}
```

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
