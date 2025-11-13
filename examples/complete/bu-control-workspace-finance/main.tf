# Complete Example - Finance BU Workspace Control
#
# This configuration manages Finance BU workspaces across multiple environments
# (dev, staging, production) with full GitOps integration, remote state sharing,
# and secure agent pool execution for sensitive operations.
#
# Resources created:
# - 4+ workspaces (web-app-dev/prod, api-service-dev/prod, database-prod)
# - GitHub repositories with VCS connections
# - Environment-specific variable sets
# - Remote state sharing configuration
# - RBAC and agent pool assignments

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.2.1"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.54.0"
    }
  }

  # Backend configuration - Finance BU control workspace
  # backend "remote" {
  #   organization = "your-enterprise-org"
  #   workspaces {
  #     name = "finance_workspace_control"
  #   }
  # }
}

# Use root bu-control-workspace module
module "finance_control" {
  source = "../../../bu-control-workspace"

  organization     = var.organization
  github_org       = var.github_org
  github_org_owner = var.github_org_owner
  oauth_token_id   = var.oauth_token_id
  bu_projects      = var.bu_projects
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "varsetMap" {
  description = "Map of variable sets by name"
  value       = module.finance_control.varsetMap
}

output "variable_set" {
  description = "Created variable set instances"
  value       = module.finance_control.variable_set
  sensitive   = true
}

output "project_id" {
  description = "Map of created workspace IDs"
  value       = module.finance_control.project_id
}

output "bu_projects" {
  description = "Business unit project ID mappings"
  value       = module.finance_control.bu_projects
}

# Convenience outputs
output "workspace_names" {
  description = "List of created workspace names"
  value       = keys(module.finance_control.project_id)
}

output "workspace_summary" {
  description = "Summary of created workspaces by environment"
  value = {
    total = length(keys(module.finance_control.project_id))
    by_environment = {
      development = length([for k in keys(module.finance_control.project_id) : k if can(regex("-dev$", k))])
      staging     = length([for k in keys(module.finance_control.project_id) : k if can(regex("-stg$", k))])
      production  = length([for k in keys(module.finance_control.project_id) : k if can(regex("-prod$", k))])
    }
  }
}
