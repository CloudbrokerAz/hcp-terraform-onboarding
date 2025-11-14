# ============================================================================
# Stack Outputs
# ============================================================================

output "environment" {
  type        = string
  description = "Deployment environment"
  value       = var.environment
}

output "workspace_ids" {
  type        = map(string)
  description = "Map of workspace names to IDs"
  value       = component.bu_onboarding.workspace_ids_map
}

output "workspace_names" {
  type        = list(string)
  description = "List of workspace names created"
  value       = component.bu_onboarding.workspace_names
}

output "variable_set_ids" {
  type        = map(string)
  description = "Map of variable set IDs"
  value       = component.bu_onboarding.variable_set_ids_map
}

output "deployment_summary" {
  type = object({
    business_unit     = string
    environment       = string
    workspaces_count  = number
    var_sets_count    = number
  })
  description = "Summary of deployed resources"
  value       = component.bu_onboarding.deployment_summary
}
