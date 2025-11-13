output "bu_admin_team_ids" {
  description = "Map of BU admin team IDs indexed by business unit name. Use these IDs for team assignments, access control, or downstream Terraform configurations. Format: { 'bu-name' = 'team-xxxxx' }"
  value       = { for k, v in tfe_team.bu_admin : k => v.id }
}

output "bu_admin_team_names" {
  description = "Map of BU admin team names indexed by business unit name. Format: { 'bu-name' = 'bu-name_admin' }"
  value       = { for k, v in tfe_team.bu_admin : k => v.name }
}

output "bu_control_project_ids" {
  description = "Map of BU control project IDs indexed by business unit name. These projects contain the BU control workspaces. Format: { 'bu-name' = 'prj-xxxxx' }"
  value       = { for k, v in tfe_project.bu_control : k => v.id }
}

output "bu_control_project_names" {
  description = "Map of BU control project names indexed by business unit name. Format: { 'bu-name' = 'bu-name_control' }"
  value       = { for k, v in tfe_project.bu_control : k => v.name }
}

output "bu_control_workspace_ids" {
  description = "Map of BU control workspace IDs indexed by business unit name. These workspaces manage BU-specific infrastructure. Format: { 'bu-name' = 'ws-xxxxx' }"
  value       = { for k, v in tfe_workspace.bu_control : k => v.id }
}

output "bu_control_workspace_names" {
  description = "Map of BU control workspace names indexed by business unit name. Format: { 'bu-name' = 'bu-name_workspace_control' }"
  value       = { for k, v in tfe_workspace.bu_control : k => v.name }
}

output "consumer_projects" {
  description = "Complete map of all consumer projects created for business units with their full configuration including IDs, team assignments, and variable sets. Used by BU control workspaces to reference project details."
  value       = module.consumer_project
}

output "consumer_project_ids" {
  description = "Map of consumer project IDs indexed by '{bu}_{project}' key. Use for workspace assignments and access control. Format: { 'bu-name_project-name' = 'prj-xxxxx' }"
  value       = { for k, v in module.consumer_project : k => v.project_id }
}

output "consumer_project_names" {
  description = "Map of consumer project names indexed by '{bu}_{project}' key. Format: { 'bu-name_project-name' = 'bu-name_project-name' }"
  value       = { for k, v in module.consumer_project : k => v.project_name }
}

output "variable_set_ids" {
  description = "Map of BU admin variable set IDs indexed by business unit name. These variable sets contain TFE_TOKEN and bu_projects variables. Format: { 'bu-name' = 'varset-xxxxx' }"
  value       = { for k, v in tfe_variable_set.bu_admin : k => v.id }
}

output "variable_set_names" {
  description = "Map of variable set names indexed by business unit name. Format: { 'bu-name' = 'bu-name_admin' }"
  value       = { for k, v in tfe_variable_set.bu_admin : k => v.name }
}

output "bu_projects_mappings" {
  description = "Map of business unit project ID mappings in JSON format. Each BU has a map of project names to project IDs. This is stored in variable sets for BU control workspaces. Format: { 'bu-name' = '{\"project1\":\"prj-xxx\",\"project2\":\"prj-yyy\"}' }"
  value       = { for k, v in tfe_variable.bu_projects : k => v.value }
  sensitive   = false
}

output "bu_projects_access" {
  description = "Processed project access configuration from YAML showing BU/project relationships and team permissions. Useful for auditing project structure and access controls. Contains bu, project, and team_project_access details."
  value       = local.bu_projects_access
}

output "business_units" {
  description = "List of all business units configured in this module. Derived from YAML configuration files. Useful for iteration or validation."
  value       = keys(local.tenant)
}

output "tenant_configuration" {
  description = "Complete tenant configuration derived from YAML files. Shows all BU settings, teams, and projects. Useful for debugging or auditing YAML parsing."
  value       = local.tenant
  sensitive   = false
} 