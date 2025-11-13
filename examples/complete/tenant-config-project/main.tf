# Complete Example - Platform Team Multi-BU Configuration
#
# This configuration creates enterprise-grade platform infrastructure for
# onboarding multiple business units (Finance, Engineering, Marketing) to
# HCP Terraform with full RBAC, SSO integration, and environment separation.
#
# Resources created:
# - 3 BU admin teams with SSO
# - 9 consumer projects (3 per BU: dev, staging, production)
# - 3 BU control projects and workspaces
# - Variable sets with BU admin tokens
# - Custom RBAC configurations
# - Environment-specific variable sets

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.54.0"
    }
  }

  # Backend configuration for platform team state
  # Uncomment and configure for your organization
  # backend "remote" {
  #   organization = "your-enterprise-org"
  #   workspaces {
  #     name = "platform-team-multi-bu"
  #   }
  # }
}

# Use the root tenant-config-project module
module "platform_team" {
  source = "../../../tenant-config-project"

  tfc_organization_name = var.tfc_organization_name
  business_unit         = var.business_unit
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "projects" {
  description = "All created consumer projects with IDs and configurations"
  value       = module.platform_team.projects
}

output "projects_project_access" {
  description = "Project access configuration details for all BUs"
  value       = module.platform_team.projects_project_access
}

# Finance BU outputs
output "finance_projects_json" {
  description = "Finance BU project IDs in JSON format for bu-control-workspace"
  value = jsonencode({
    for key, project in module.platform_team.projects :
    trimprefix(key, "finance_") => project.project_id
    if startswith(key, "finance_")
  })
}

output "finance_project_ids" {
  description = "Finance BU project IDs for easy reference"
  value = {
    for key, project in module.platform_team.projects :
    key => project.project_id
    if startswith(key, "finance_")
  }
}

# Engineering BU outputs
output "engineering_projects_json" {
  description = "Engineering BU project IDs in JSON format for bu-control-workspace"
  value = jsonencode({
    for key, project in module.platform_team.projects :
    trimprefix(key, "engineering_") => project.project_id
    if startswith(key, "engineering_")
  })
}

output "engineering_project_ids" {
  description = "Engineering BU project IDs for easy reference"
  value = {
    for key, project in module.platform_team.projects :
    key => project.project_id
    if startswith(key, "engineering_")
  }
}

# Marketing BU outputs
output "marketing_projects_json" {
  description = "Marketing BU project IDs in JSON format for bu-control-workspace"
  value = jsonencode({
    for key, project in module.platform_team.projects :
    trimprefix(key, "marketing_") => project.project_id
    if startswith(key, "marketing_")
  })
}

output "marketing_project_ids" {
  description = "Marketing BU project IDs for easy reference"
  value = {
    for key, project in module.platform_team.projects :
    key => project.project_id
    if startswith(key, "marketing_")
  }
}

# Summary outputs
output "summary" {
  description = "Summary of created resources"
  value = {
    total_projects      = length(module.platform_team.projects)
    business_units      = distinct([for k, v in module.platform_team.projects : v.bu])
    projects_by_bu = {
      for bu in distinct([for k, v in module.platform_team.projects : v.bu]) :
      bu => length([for k, v in module.platform_team.projects : v if v.bu == bu])
    }
  }
}
