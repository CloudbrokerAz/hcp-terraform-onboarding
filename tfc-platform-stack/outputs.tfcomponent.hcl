# ============================================================================
# Stack Outputs
# ============================================================================

output "organization_name" {
  type        = string
  description = "HCP Terraform organization name"
  value       = component.platform_onboarding.organization_name
}

output "business_units" {
  type        = list(string)
  description = "List of business units managed"
  value       = component.platform_onboarding.business_units
}

output "bu_infrastructure" {
  type = map(object({
    organization     = string
    project_id       = string
    project_name     = string
    team_id          = string
    workspace_id     = string
    workspace_name   = string
    variable_set_id  = string
    github_repo_name = optional(string)
    github_repo_url  = optional(string)
    github_team_id   = optional(string)
    consumer_projects = map(object({
      id   = string
      name = string
    }))
  }))
  description = "Complete infrastructure mapping per BU for downstream consumption"
  value       = component.platform_onboarding.bu_infrastructure
}

output "bu_project_ids_map" {
  type        = map(string)
  description = "Map of BU names to control project IDs"
  value       = component.platform_onboarding.bu_project_ids_map
}

output "bu_admin_tokens" {
  type        = map(string)
  description = "Map of BU names to admin team tokens (sensitive)"
  value       = component.platform_onboarding.bu_admin_tokens
  sensitive   = true
}

output "bu_stack_repo_names" {
  type        = map(string)
  description = "Map of BU names to Stack repository names"
  value       = component.platform_onboarding.bu_stack_repo_names
}

output "bu_stack_repo_urls" {
  type        = map(string)
  description = "Map of BU names to Stack repository URLs"
  value       = component.platform_onboarding.bu_stack_repo_urls
}

output "deployment_summary" {
  type = object({
    business_units_count    = number
    bu_projects_count       = number
    consumer_projects_count = number
    bu_teams_count          = number
    bu_workspaces_count     = number
    github_repos_created    = number
    github_teams_created    = number
  })
  description = "Summary of resources created"
  value       = component.platform_onboarding.deployment_summary
}
