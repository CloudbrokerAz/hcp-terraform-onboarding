
output "varsetMap" {
  description = "Map of variable sets by name, showing workspace associations and configurations. Used for tracking which variable sets are applied to which workspaces."
  value       = local.varsetMap
}

output "variable_set" {
  description = "Created variable set module instances containing IDs and attributes for all variable sets provisioned by this module. Useful for downstream dependencies or audit purposes."
  value       = module.terraform-tfe-variable-sets
  sensitive   = true
}

output "project_id" {
  description = "Map of created workspace IDs indexed by workspace name. Use this to reference workspaces in other Terraform configurations or for integration with external systems."
  value       = module.workspace
}

output "bu_projects" {
  description = "Business unit project ID mappings passed from the platform team tenant configuration. Maps project names to their TFC project IDs for workspace assignment."
  value       = var.bu_projects
}