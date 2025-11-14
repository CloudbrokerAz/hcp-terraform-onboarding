# ============================================================================
# Consumer Projects (BU-specific application/workload projects)
# ============================================================================

resource "tfe_project" "consumer" {
  for_each = local.bu_projects_access

  name         = "BU_${each.value.bu}_${each.value.project}"
  organization = var.tfc_organization_name
  description  = try(each.value.value.description, "${each.value.bu} ${each.value.project} project")
}

# ============================================================================
# Consumer Project Team Access
# ============================================================================

resource "tfe_team_project_access" "consumer_admin" {
  for_each = local.bu_projects_access

  access     = "admin"
  project_id = tfe_project.consumer[each.key].id
  team_id    = tfe_team.bu_admin[each.value.bu].id
}

# ============================================================================
# Consumer Project Variable Sets (if defined in YAML)
# ============================================================================

resource "tfe_variable_set" "consumer_project" {
  for_each = {
    for k, v in local.bu_projects_access : k => v
    if length(try(v.value.var_sets.variables, {})) > 0
  }

  name         = "BU_${each.value.bu}_${each.value.project}_vars"
  description  = "Variable set for ${each.value.bu} ${each.value.project} project"
  organization = var.tfc_organization_name
  global       = try(each.value.value.var_sets.global, false)
}

resource "tfe_variable" "consumer_project_vars" {
  for_each = merge([
    for proj_key, proj_val in local.bu_projects_access : {
      for var_key, var_val in try(proj_val.value.var_sets.variables, {}) :
      "${proj_key}_${var_key}" => {
        var_set_id  = tfe_variable_set.consumer_project[proj_key].id
        key         = var_key
        value       = try(var_val.value, "")
        category    = try(var_val.category, "terraform")
        description = try(var_val.description, "")
        hcl         = try(var_val.hcl, false)
        sensitive   = try(var_val.sensitive, false)
      }
      if length(try(proj_val.value.var_sets.variables, {})) > 0
    }
  ]...)

  key             = each.value.key
  value           = each.value.value
  category        = each.value.category
  description     = each.value.description
  hcl             = each.value.hcl
  sensitive       = each.value.sensitive
  variable_set_id = each.value.var_set_id
}

resource "tfe_project_variable_set" "consumer_project" {
  for_each = {
    for k, v in local.bu_projects_access : k => v
    if length(try(v.value.var_sets.variables, {})) > 0
  }

  variable_set_id = tfe_variable_set.consumer_project[each.key].id
  project_id      = tfe_project.consumer[each.key].id
}
