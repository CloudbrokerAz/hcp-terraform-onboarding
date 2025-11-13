output "workspace_ids" {
  description = "Map of created workspace IDs indexed by workspace name. Use these IDs for remote state access, run triggers, or other workspace references. Format: { 'workspace-name' = 'ws-xxxxx' }"
  value       = { for k, v in module.workspace : k => v.workspace_id }
}

output "workspace_names" {
  description = "List of all workspace names created by this module. Useful for iteration or validation."
  value       = keys(module.workspace)
}

output "workspace_details" {
  description = "Complete workspace module output containing all workspace attributes including IDs, names, URLs, and configurations. Use for comprehensive workspace information."
  value       = module.workspace
}

output "github_repositories" {
  description = "Map of GitHub repository details indexed by workspace/repository name. Contains repository URLs, SSH/HTTP URLs, and full names. Only includes repositories created by this module (create_repo=true)."
  value       = module.github
  sensitive   = false
}

output "github_repository_urls" {
  description = "Map of GitHub repository HTML URLs indexed by repository name. Quick reference for repository access. Format: { 'repo-name' = 'https://github.com/org/repo' }"
  value       = { for k, v in module.github : k => v.github_repo }
}

output "variable_sets" {
  description = "Map of created variable set details indexed by variable set name. Contains variable set IDs, names, and associated variables. Use for tracking variable set configurations."
  value       = module.terraform-tfe-variable-sets
  sensitive   = true
}

output "variable_set_ids" {
  description = "Map of variable set IDs indexed by variable set name. Use for variable set associations or downstream references. Format: { 'varset-name' = 'varset-xxxxx' }"
  value       = { for k, v in module.terraform-tfe-variable-sets : k => v.variable_set[0].id }
}

output "variable_set_workspace_associations" {
  description = "Map showing which variable sets are associated with which workspaces. Format: { 'varset-name' = { 'workspace_name' = 'ws-name', 'variable_set_id' = 'varset-xxx' } }"
  value = {
    for k, v in local.varsetMap : k => {
      workspace_name  = v.workspace_name
      variable_set_id = try(module.terraform-tfe-variable-sets[k].variable_set[0].id, null)
    }
  }
}

output "varsetMap" {
  description = "Internal variable set mapping structure showing workspace associations and configurations. Useful for debugging YAML parsing and variable set logic."
  value       = local.varsetMap
}

output "bu_projects" {
  description = "Business unit project ID mappings passed from platform team tenant configuration. Maps project names to their TFC project IDs for workspace assignment. Format: '{\"project1\":\"prj-xxx\",\"project2\":\"prj-yyy\"}'"
  value       = var.bu_projects
}

output "bu_projects_decoded" {
  description = "Decoded business unit project mappings as a map object. Easier to use in Terraform expressions than JSON string. Format: { 'project1' = 'prj-xxx', 'project2' = 'prj-yyy' }"
  value       = jsondecode(var.bu_projects)
}

output "workspace_configuration" {
  description = "Parsed workspace configuration from YAML files showing all workspace settings. Useful for debugging YAML parsing and workspace structure."
  value       = local.workspaces
  sensitive   = false
}

output "workspaces_with_repos" {
  description = "List of workspace names that have GitHub repositories created (create_repo=true). Useful for tracking VCS-connected workspaces."
  value       = keys(local.workspaceRepos)
}

output "workspaces_with_variable_sets" {
  description = "List of workspace names that have variable sets configured (create_variable_set=true). Useful for tracking variable set usage."
  value       = keys(local.ws_varSets)
}

output "all_workspace_ids_data" {
  description = "Data source output containing all workspace IDs in the organization. Includes workspaces not managed by this module. Use for cross-workspace references."
  value       = data.tfe_workspace_ids.all.ids
  sensitive   = false
}