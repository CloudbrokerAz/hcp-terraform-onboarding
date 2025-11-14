# ============================================================================
# Workspaces
# ============================================================================

resource "tfe_workspace" "this" {
  for_each = local.workspaces

  name         = each.value.workspace_name
  organization = var.tfc_organization_name
  project_id   = var.bu_project_id
  
  description      = try(each.value.workspace_description, "Managed by bu-onboarding module")
  terraform_version = try(each.value.workspace_terraform_version, "")
  
  # Execution settings
  execution_mode      = try(each.value.execution_mode, "remote")
  agent_pool_id       = try(each.value.workspace_agents, false) && try(each.value.agent_pool_name, null) != null ? data.tfe_agent_pool.selected[each.key].id : null
  auto_apply          = try(each.value.workspace_auto_apply, false)
  queue_all_runs      = var.queue_all_runs || try(each.value.queue_all_runs, false)
  assessments_enabled = var.enable_assessments || try(each.value.assessments_enabled, false)
  
  # File triggers
  file_triggers_enabled = try(each.value.file_triggers_enabled, true)
  working_directory     = try(each.value.workspace_vcs_directory, null) == "root_directory" ? null : try(each.value.workspace_vcs_directory, null)
  trigger_prefixes      = try(each.value.trigger_prefixes, null)
  trigger_patterns      = try(each.value.trigger_patterns, null)
  
  # VCS repository configuration
  dynamic "vcs_repo" {
    for_each = try(each.value.vcs_repo, null) != null ? [each.value.vcs_repo] : []
    
    content {
      identifier     = vcs_repo.value.identifier
      branch         = try(vcs_repo.value.branch, "main")
      oauth_token_id = var.vcs_oauth_token_id
    }
  }
  
  # Tags
  tag_names = try(each.value.workspace_tags, [])
  
  lifecycle {
    ignore_changes = [vcs_repo]
  }
}

# ============================================================================
# Agent Pool Data Source (if needed)
# ============================================================================

data "tfe_agent_pool" "selected" {
  for_each = {
    for k, v in local.workspaces : k => v
    if try(v.workspace_agents, false) && try(v.agent_pool_name, null) != null
  }
  
  name         = each.value.agent_pool_name
  organization = var.tfc_organization_name
}

# ============================================================================
# Workspace Variables
# ============================================================================

resource "tfe_variable" "workspace_vars" {
  for_each = merge([
    for ws_key, workspace in local.workspaces : {
      for var_key, variable in try(workspace.variables, {}) :
      "${ws_key}__${var_key}" => {
        workspace_id = tfe_workspace.this[ws_key].id
        key          = var_key
        value        = variable.value
        category     = try(variable.category, "terraform")
        description  = try(variable.description, "")
        hcl          = try(variable.hcl, false)
        sensitive    = try(variable.sensitive, false)
      }
    }
  ]...)

  workspace_id = each.value.workspace_id
  key          = each.value.key
  value        = each.value.value
  category     = each.value.category
  description  = each.value.description
  hcl          = each.value.hcl
  sensitive    = each.value.sensitive
}

# ============================================================================
# Remote State Access (if enabled)
# ============================================================================

resource "tfe_workspace_settings" "remote_state" {
  for_each = {
    for k, v in local.workspaces : k => v
    if var.enable_remote_state_sharing && try(v.remote_state, false)
  }
  
  workspace_id   = tfe_workspace.this[each.key].id
  execution_mode = try(each.value.execution_mode, "remote")
}

# Note: Remote state consumer setup would require workspace IDs
# This is typically managed at deployment time or via separate configuration

# ============================================================================
# Variable Sets
# ============================================================================

resource "tfe_variable_set" "this" {
  for_each = local.variable_sets

  name         = each.value.var_sets.variable_set_name
  description  = try(each.value.var_sets.variable_set_description, "")
  organization = var.tfc_organization_name
  global       = try(each.value.var_sets.global, false)
}

resource "tfe_variable" "varset_vars" {
  for_each = merge([
    for vs_key, varset in local.variable_sets : {
      for var_key, variable in try(varset.var_sets.variables, {}) :
      "${vs_key}__${var_key}" => {
        variable_set_id = tfe_variable_set.this[vs_key].id
        key             = var_key
        value           = variable.value
        category        = try(variable.category, "terraform")
        description     = try(variable.description, "")
        hcl             = try(variable.hcl, false)
        sensitive       = try(variable.sensitive, false)
      }
    }
  ]...)

  variable_set_id = each.value.variable_set_id
  key             = each.value.key
  value           = each.value.value
  category        = each.value.category
  description     = each.value.description
  hcl             = each.value.hcl
  sensitive       = each.value.sensitive
}

# ============================================================================
# Associate Variable Sets with Workspaces
# ============================================================================

resource "tfe_workspace_variable_set" "association" {
  for_each = local.variable_sets

  variable_set_id = tfe_variable_set.this[each.key].id
  workspace_id    = tfe_workspace.this[each.value.workspace_name].id
}

# ============================================================================
# Workspace IDs Data Source (for reference)
# ============================================================================

data "tfe_workspace_ids" "all" {
  depends_on = [tfe_workspace.this]
  
  names        = ["*"]
  organization = var.tfc_organization_name
}
