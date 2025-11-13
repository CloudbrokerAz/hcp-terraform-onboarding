# Basic Example - BU Team Workspace Control Configuration
#
# This configuration creates BU-level workspaces and infrastructure after the
# platform team has created the foundational projects and teams.
#
# Resources created:
# - 2 Workspaces (finance-web-app, finance-api-service)
# - 2 GitHub repositories from template
# - VCS connections for GitOps workflows
# - Variable sets for workspace configuration

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

  # Configure your backend here
  # backend "remote" {
  #   organization = "your-org-name"
  #   workspaces {
  #     name = "finance-workspace-control"
  #   }
  # }
}

# Use the root module configuration
module "bu_control" {
  source = "../../../bu-control-workspace"

  organization     = var.organization
  github_org       = var.github_org
  github_org_owner = var.github_org_owner
  oauth_token_id   = var.oauth_token_id
  bu_projects      = var.bu_projects
}

# Outputs from the BU control layer
output "varsetMap" {
  description = "Map of variable sets by name with workspace associations"
  value       = module.bu_control.varsetMap
}

output "variable_set" {
  description = "Created variable set module instances"
  value       = module.bu_control.variable_set
  sensitive   = true
}

output "project_id" {
  description = "Map of created workspace IDs"
  value       = module.bu_control.project_id
}

output "bu_projects" {
  description = "Business unit project ID mappings"
  value       = module.bu_control.bu_projects
}

# Convenience output: List of created workspaces
output "workspace_names" {
  description = "List of created workspace names for easy reference"
  value       = keys(module.bu_control.project_id)
}
