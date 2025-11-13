# Basic Example - Platform Team Tenant Configuration
#
# This configuration creates the platform-level infrastructure for onboarding
# the finance business unit to HCP Terraform.
#
# Resources created:
# - BU admin team (finance_admin)
# - BU control project (finance_control)
# - BU control workspace (finance_workspace_control)
# - Consumer project (finance_app-dev)
# - Variable sets with BU admin tokens
# - RBAC assignments

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.54.0"
    }
  }

  # Configure your backend here
  # backend "remote" {
  #   organization = "your-org-name"
  #   workspaces {
  #     name = "platform-team-onboarding"
  #   }
  # }
}

# Use the root module configuration
module "platform_team" {
  source = "../../../tenant-config-project"

  tfc_organization_name = var.tfc_organization_name
  business_unit         = var.business_unit
}

# Outputs from the platform team layer
output "projects" {
  description = "Created consumer projects with IDs and configurations"
  value       = module.platform_team.projects
}

output "projects_project_access" {
  description = "Project access configuration details"
  value       = module.platform_team.projects_project_access
}

# Output the project ID in a format ready for bu-control-workspace
output "bu_projects_json" {
  description = "JSON-formatted project IDs for bu-control-workspace configuration"
  value = jsonencode({
    for key, project in module.platform_team.projects : key => project.project_id
  })
}
