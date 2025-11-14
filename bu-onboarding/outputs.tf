# ============================================================================
# Workspace Outputs
# ============================================================================

output "workspace_ids_map" {
  description = "Map of workspace names to workspace IDs"
  value = {
    for k, v in tfe_workspace.this :
    k => v.id
  }
}

output "workspace_names" {
  description = "List of all workspace names created"
  value       = keys(tfe_workspace.this)
}

output "workspace_urls" {
  description = "Map of workspace names to HCP Terraform URLs"
  value = {
    for k, v in tfe_workspace.this :
    k => "https://app.terraform.io/app/${var.tfc_organization_name}/workspaces/${v.name}"
  }
}

output "workspace_details" {
  description = "Complete workspace resource details"
  value       = tfe_workspace.this
}

# ============================================================================
# Variable Set Outputs
# ============================================================================

output "variable_set_ids_map" {
  description = "Map of variable set names to IDs"
  value = {
    for k, v in tfe_variable_set.this :
    k => v.id
  }
}

output "variable_set_names" {
  description = "List of variable set names created"
  value       = keys(tfe_variable_set.this)
}

output "variable_set_workspace_associations" {
  description = "Map showing variable set to workspace associations"
  value = {
    for k, v in local.variable_sets :
    k => {
      workspace_name  = v.workspace_name
      variable_set_id = tfe_variable_set.this[k].id
      workspace_id    = tfe_workspace.this[v.workspace_name].id
    }
  }
}

# ============================================================================
# Deployment Summary
# ============================================================================

output "deployment_summary" {
  description = "Summary of resources created by this deployment"
  value = {
    business_unit    = var.business_unit
    environment      = var.environment
    workspaces_count = length(tfe_workspace.this)
    var_sets_count   = length(tfe_variable_set.this)
    project_id       = var.bu_project_id
    organization     = var.tfc_organization_name
  }
}

# ============================================================================
# Configuration Debugging Outputs
# ============================================================================

output "workspace_configuration" {
  description = "Parsed workspace configuration from YAML (for debugging)"
  value       = local.workspaces
  sensitive   = false
}

output "workspaces_with_vcs" {
  description = "List of workspace names with VCS repo configured"
  value = [
    for k, v in local.workspaces :
    k if try(v.vcs_repo, null) != null
  ]
}

output "workspaces_with_agents" {
  description = "List of workspace names using agent execution"
  value = [
    for k, v in local.workspaces :
    k if try(v.workspace_agents, false)
  ]
}

output "workspaces_with_auto_apply" {
  description = "List of workspace names with auto-apply enabled"
  value = [
    for k, v in local.workspaces :
    k if try(v.workspace_auto_apply, false)
  ]
}

# ============================================================================
# All Workspace IDs (Organization-wide)
# ============================================================================

output "all_workspace_ids" {
  description = "All workspace IDs in the organization (not just managed by this module)"
  value       = data.tfe_workspace_ids.all.ids
  sensitive   = false
}
