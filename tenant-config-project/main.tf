resource "tfe_team" "bu_admin" {
  for_each = local.tenant

  name         = "${each.value.bu}_admin"
  organization = var.tfc_organization_name
  sso_team_id  = try(each.value.value.team.sso_team_id, null)
}

resource "tfe_team_token" "bu_admin" {
  for_each = local.tenant
  team_id  = tfe_team.bu_admin[each.key].id
}

resource "tfe_variable_set" "bu_admin" {
  for_each = local.tenant

  name         = "${each.value.bu}_admin"
  description  = "${each.value.bu} varset Managed by Terraform"
  organization = var.tfc_organization_name
}

resource "tfe_variable" "bu_admin" {
  for_each = local.tenant

  key             = "TFE_TOKEN"
  value           = tfe_team_token.bu_admin[each.key].token
  category        = "env"
  description     = "${each.value.bu} TFE Team Token"
  sensitive       = true
  variable_set_id = tfe_variable_set.bu_admin[each.key].id
}

resource "tfe_variable" "bu_projects" {
  for_each = local.tenant

  key             = "bu_projects"
  value           = jsonencode({ for projectKey, projectValue in module.consumer_project : projectKey => projectValue.project_id if projectValue.bu == "${each.value.bu}" })
  category        = "terraform"
  description     = "${each.value.bu} bu project ids"
  sensitive       = false
  variable_set_id = tfe_variable_set.bu_admin[each.key].id
}


resource "tfe_project_variable_set" "bu_admin" {
  for_each        = local.tenant
  variable_set_id = tfe_variable_set.bu_admin[each.key].id
  project_id      = tfe_project.bu_control[each.key].id
}

resource "tfe_project" "bu_control" {
  for_each = local.tenant

  name         = "${each.value.bu}_control"
  organization = var.tfc_organization_name
}

resource "tfe_team_project_access" "bu_control" {
  for_each = local.tenant

  access     = "admin"
  project_id = tfe_project.bu_control[each.key].id
  team_id    = tfe_team.bu_admin[each.key].id
}

/* data "tfe_project" "platform_team" {
  name         = "platform_team"
  organization = var.tfc_organization_name
}

# allow bu admins to read the platform workspace outputs
resource "tfe_team_project_access" "read_output" {
  for_each   = local.tenant
  access       = "custom"
  team_id      = tfe_team.bu_admin[each.key].id
  project_id   = data.tfe_project.platform_team.id

  project_access {
    settings = "read"
    teams    = "none"
  }
  workspace_access {
    state_versions = "read-outputs"
    sentinel_mocks = "none"
    runs           = "read"
    variables      = "none"
    create         = false
    locking        = false
    move           = false
    delete         = false
    run_tasks      = false
  }
}
 */
resource "tfe_workspace" "bu_control" {
  for_each           = local.tenant
  name               = "${each.value.bu}_workspace_control"
  organization       = var.tfc_organization_name
  auto_apply         = false
  allow_destroy_plan = false
  project_id         = tfe_project.bu_control[each.key].id
}

# Create the project and teams in Terraform Cloud
module "consumer_project" {
  source   = "github.com/hashi-demo-lab/terraform-tfe-project-team?ref=0.1.2"
  for_each = local.bu_projects_access


  organization_name   = var.tfc_organization_name
  project_name        = "${each.value.bu}_${each.value.project}"
  project_description = each.value.value.description
  business_unit       = each.value.bu

  team_project_access        = try(each.value.value.team_project_access, {})
  custom_team_project_access = try(each.value.value.custom_team_project_access, {})

  bu_control_admins_id = tfe_team.bu_admin[each.value.bu].id

  # Passing var_sets data correctly
  create_variable_set = length(try(each.value.value.var_sets, {})) > 0 ? true : false
  varset = {
    variable_set_name        = "${each.value.bu}_${each.value.project}_vars"
    variable_set_description = "Variable set for ${each.value.bu}_${each.value.project}"
    variables                = try(each.value.value.var_sets, {})
    tags                     = try(each.value.value.var_sets.tags, []) # Defaulting to empty list if missing
    global                   = try(each.value.value.var_sets.global, false) # Defaulting to false if not provided
  }
}


/* resource "tfe_team_project_access" "read_output" {
  for_each   = { for key in local.read-outputs : key => local.read-outputs[key].team_project_access }
  access       = "custom"
  team_id      = module.consumer_project[each.key].team_id
  project_id   = module.consumer_project[each.value.read_outputs.key]

  project_access {
    settings = "read"
    teams    = "none"
  }
  workspace_access {
    state_versions = "read-outputs"
    sentinel_mocks = "none"
    runs           = "read"
    variables      = "none"
    create         = false
    locking        = false
    move           = false
    delete         = false
    run_tasks      = false
  }
} */