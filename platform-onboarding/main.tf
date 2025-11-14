# ============================================================================
# BU Admin Teams
# ============================================================================

resource "tfe_team" "bu_admin" {
  for_each = local.tenant

  name         = "${each.key}_admin"
  organization = var.tfc_organization_name
  sso_team_id  = try(each.value.team.sso_team_id, null)
}

# ============================================================================
# BU Admin Team Tokens
# ============================================================================

resource "tfe_team_token" "bu_admin" {
  for_each = local.tenant
  
  team_id = tfe_team.bu_admin[each.key].id
}

# ============================================================================
# BU Control Projects
# ============================================================================

resource "tfe_project" "bu_control" {
  for_each = local.tenant

  name         = "BU_${each.key}"
  organization = var.tfc_organization_name
  description  = "Control project for ${each.key} business unit"
}

# ============================================================================
# BU Admin Team Access to Control Projects
# ============================================================================

resource "tfe_team_project_access" "bu_control" {
  for_each = local.tenant

  access     = "admin"
  project_id = tfe_project.bu_control[each.key].id
  team_id    = tfe_team.bu_admin[each.key].id
}

# ============================================================================
# BU Control Workspaces
# ============================================================================

resource "tfe_workspace" "bu_control" {
  for_each = local.tenant

  name               = "${each.key}_workspace_control"
  organization       = var.tfc_organization_name
  description        = "Control workspace for ${each.key} BU infrastructure management"
  project_id         = tfe_project.bu_control[each.key].id
  auto_apply         = false
  allow_destroy_plan = false
  
  lifecycle {
    ignore_changes = [
      vcs_repo, # May be configured via Stack VCS connection
    ]
  }
}

# ============================================================================
# BU Variable Sets (contains team tokens)
# ============================================================================

resource "tfe_variable_set" "bu_admin" {
  for_each = local.tenant

  name         = "${each.key}_admin"
  description  = "${each.key} BU admin variable set - Managed by Platform Team"
  organization = var.tfc_organization_name
}

resource "tfe_variable" "bu_admin_token" {
  for_each = local.tenant

  key             = "TFE_TOKEN"
  value           = tfe_team_token.bu_admin[each.key].token
  category        = "env"
  description     = "${each.key} BU admin team token"
  sensitive       = true
  variable_set_id = tfe_variable_set.bu_admin[each.key].id
}

resource "tfe_variable" "bu_projects" {
  for_each = local.tenant

  key    = "bu_projects"
  value  = jsonencode({
    for proj_key, proj_val in tfe_project.consumer : 
    proj_key => proj_val.id 
    if startswith(proj_key, "${each.key}_")
  })
  category        = "terraform"
  description     = "${each.key} BU project IDs mapping"
  sensitive       = false
  variable_set_id = tfe_variable_set.bu_admin[each.key].id
}

# ============================================================================
# Associate Variable Sets with Control Projects
# ============================================================================

resource "tfe_project_variable_set" "bu_admin" {
  for_each = local.tenant

  variable_set_id = tfe_variable_set.bu_admin[each.key].id
  project_id      = tfe_project.bu_control[each.key].id
}
