# Publishing and Bootstrap Architecture Diagrams

## Publishing Strategy: Monorepo with Tag Prefixes

```
┌─────────────────────────────────────────────────────────────────┐
│  Repository: hcp-terraform-onboarding                           │
│  URL: github.com/CloudbrokerAz/hcp-terraform-onboarding         │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  tenant-config-project/                                   │  │
│  │  ├── main.tf                                              │  │
│  │  ├── variables.tf                                         │  │
│  │  ├── outputs.tf                                           │  │
│  │  ├── versions.tf                                          │  │
│  │  └── config/                                              │  │
│  │      └── *.yaml                                           │  │
│  │                                                           │  │
│  │  Git Tag: tenant-v1.0.0 ─────────────────────────┐       │  │
│  └──────────────────────────────────────────────────┼───────┘  │
│                                                      │          │
│  ┌──────────────────────────────────────────────────┼───────┐  │
│  │  bu-control-workspace/                           │       │  │
│  │  ├── main.tf                                     │       │  │
│  │  ├── variables.tf                                │       │  │
│  │  ├── outputs.tf                                  │       │  │
│  │  ├── versions.tf                                 │       │  │
│  │  ├── locals.tf                                   │       │  │
│  │  └── config/                                     │       │  │
│  │      └── *.yaml                                  │       │  │
│  │                                                  │       │  │
│  │  Git Tag: bu-v1.0.0 ─────────────────────────────┘       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────┬──────────────────┬────────────────────────────┘
                  │                  │
                  │ Webhook          │ Webhook
                  ▼                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  HCP Terraform Private Module Registry                           │
│                                                                   │
│  ┌────────────────────────────────┐  ┌────────────────────────┐ │
│  │ Module: tenant-config          │  │ Module: bu-workspace   │ │
│  │ Provider: tfe                  │  │ Provider: tfe          │ │
│  │ Version: 1.0.0                 │  │ Version: 1.0.0         │ │
│  │                                │  │                        │ │
│  │ Address:                       │  │ Address:               │ │
│  │ YOUR-ORG/tenant-config/tfe     │  │ YOUR-ORG/bu-workspace/tfe│
│  └────────────────────────────────┘  └────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Bootstrap Workspace Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Manual One-Time Setup (You Already Did This!)         │
│                                                                 │
│  In HCP Terraform UI:                                           │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Project: platform_team (manually created)                 │ │
│  │   └── Workspace: tenant-config (manually created)         │ │
│  │       ├── VCS: NOT YET CONNECTED                          │ │
│  │       ├── Variables: NONE YET                             │ │
│  │       └── Purpose: Bootstrap workspace (seeds everything) │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Configure Bootstrap Workspace (Next Step)             │
│                                                                 │
│  1. Connect to VCS:                                             │
│     Repository: CloudbrokerAz/hcp-terraform-onboarding          │
│     Branch: main                                                │
│     Working Directory: tenant-config-project                    │
│                                                                 │
│  2. Add Variables:                                              │
│     tfc_organization_name = "your-org"                          │
│     business_unit        = "finance"                            │
│                                                                 │
│  3. Add YAML Config:                                            │
│     File: tenant-config-project/config/finance.yaml             │
│     Content: BU projects and teams                              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: First Terraform Apply                                 │
│                                                                 │
│  Push YAML → Workspace auto-triggers → Plan → Apply            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  RESULT: Platform Infrastructure Created                        │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Team: finance_admin                                       │ │
│  │   └── Token: Generated and stored in variable set        │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Project: finance_control                                  │ │
│  │   └── Team Access: finance_admin (admin)                  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Workspace: finance_workspace_control                      │ │
│  │   ├── Project: finance_control                            │ │
│  │   ├── Team: finance_admin (admin access)                  │ │
│  │   ├── Variable Set: finance_admin (attached)              │ │
│  │   │   ├── TFE_TOKEN (from team token)                     │ │
│  │   │   └── bu_projects (JSON project mapping)              │ │
│  │   └── Purpose: BU team self-service workspace            │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Projects (Consumer Projects):                             │ │
│  │   ├── finance_applications                                │ │
│  │   │   └── Team Access: finance_developers (write)         │ │
│  │   └── finance_infrastructure                              │ │
│  │       └── Team Access: finance_sre (admin)                │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: BU Team Self-Service (Finance Team Takes Over)        │
│                                                                 │
│  Finance team:                                                  │
│  1. Creates repository: finance-bu-control                      │
│  2. Adds workspace YAML configs                                 │
│  3. Connects finance_workspace_control to their repo            │
│  4. Applies → Creates application workspaces                    │
└─────────────────────────────────────────────────────────────────┘
```

## Repository to Workspace Mapping

```
┌────────────────────────────────────────────────────────────────┐
│  Platform Team Repository                                      │
│  github.com/CloudbrokerAz/hcp-terraform-onboarding             │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ tenant-config-project/                                   │ │
│  │   └── config/                                            │ │
│  │       ├── finance.yaml                                   │ │
│  │       ├── engineering.yaml                               │ │
│  │       └── marketing.yaml                                 │ │
│  └──────────────────────────────────────────────────────────┘ │
│                 │                                              │
│                 │ Connected to                                 │
│                 ▼                                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ HCP Terraform Workspace                                  │ │
│  │ Project: platform_team                                   │ │
│  │ Workspace: tenant-config                                 │ │
│  │ Purpose: Bootstrap (creates everything else)             │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ Creates
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  Finance BU Infrastructure (Auto-Created)                      │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ HCP Terraform Workspace                                  │ │
│  │ Project: finance_control                                 │ │
│  │ Workspace: finance_workspace_control                     │ │
│  │ Purpose: BU self-service workspace creation              │ │
│  └──────────────────────────────────────────────────────────┘ │
│                 ▲                                              │
│                 │ Connected to                                 │
│                 │                                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ Finance BU Repository (Finance Team Creates)             │ │
│  │ github.com/YOUR-ORG/finance-bu-control                   │ │
│  │   └── config/                                            │ │
│  │       ├── finance-app-dev.yaml                           │ │
│  │       ├── finance-app-staging.yaml                       │ │
│  │       └── finance-app-prod.yaml                          │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              │
                              │ Creates
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  Application Workspaces (Auto-Created by BU)                   │
│                                                                │
│  Project: finance_applications                                 │
│    ├── Workspace: finance-app-dev                              │
│    ├── Workspace: finance-app-staging                          │
│    └── Workspace: finance-app-prod                             │
└────────────────────────────────────────────────────────────────┘
```

## Variable Flow

```
┌────────────────────────────────────────────────────────────────┐
│  Platform Team Deploys                                         │
│  Workspace: tenant-config                                      │
│                                                                │
│  Creates:                                                      │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ Variable Set: finance_admin                              │ │
│  │                                                          │ │
│  │ Variables:                                               │ │
│  │   TFE_TOKEN = "<team-token>" (sensitive)                 │ │
│  │   bu_projects = '{"applications":"prj-xxx",...}'         │ │
│  │                                                          │ │
│  │ Applied to:                                              │ │
│  │   - Project: finance_control                             │ │
│  │     └── Workspace: finance_workspace_control             │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────────────────────────────┐
│  Finance Team Uses                                             │
│  Workspace: finance_workspace_control                          │
│                                                                │
│  Has access to (via variable set):                             │
│    - TFE_TOKEN: For creating workspaces                        │
│    - bu_projects: For project ID mapping                       │
│                                                                │
│  Finance team adds (as workspace variables):                   │
│    - organization: "your-org"                                  │
│    - github_org: "your-github-org"                             │
│    - oauth_token_id: "ot-xxx"                                  │
│                                                                │
│  Creates:                                                      │
│    - Application workspaces                                    │
│    - GitHub repositories                                       │
│    - VCS connections                                           │
└────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

### 1. **One Repository → Two Modules**
Use tag prefixes to publish multiple modules from one repository.

### 2. **One Manual Workspace → Everything Else Automated**
Bootstrap workspace creates all BU infrastructure.

### 3. **Platform Team → BU Teams → Application Teams**
Clear delegation of responsibilities at each layer.

### 4. **YAML-Driven Configuration**
All infrastructure defined in version-controlled YAML files.

### 5. **VCS-Driven Workflow**
GitOps pattern: Push YAML → Workspace triggers → Infrastructure updated.
