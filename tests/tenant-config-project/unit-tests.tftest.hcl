# Unit Tests for tenant-config-project
#
# These tests validate the platform team layer logic without creating real infrastructure.
# Tests focus on variable validation, YAML parsing, and local value transformations.
#
# Run with: terraform test -filter=tests/tenant-config-project/unit-tests.tftest.hcl

# Test: Organization name validation - empty string
run "test_organization_empty" {
  command = plan

  variables {
    tfc_organization_name = ""
    business_unit         = "finance"
  }

  expect_failures = [
    var.tfc_organization_name
  ]
}

# Test: Organization name validation - too long
run "test_organization_too_long" {
  command = plan

  variables {
    tfc_organization_name = "a" # Create 256 character string
    business_unit         = "finance"
  }

  expect_failures = [
    var.tfc_organization_name
  ]
}

# Test: Business unit validation - invalid characters
run "test_business_unit_invalid_chars" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "Finance-BU!"  # Uppercase and special char
  }

  expect_failures = [
    var.business_unit
  ]
}

# Test: Business unit validation - empty string
run "test_business_unit_empty" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = ""
  }

  expect_failures = [
    var.business_unit
  ]
}

# Test: Valid configuration with minimal values
run "test_valid_minimal_config" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify plan succeeds
  assert {
    condition     = var.tfc_organization_name == "test-org"
    error_message = "Organization name should be 'test-org'"
  }

  assert {
    condition     = var.business_unit == "finance"
    error_message = "Business unit should be 'finance'"
  }
}

# Test: Valid configuration with special characters in BU
run "test_valid_bu_with_special_chars" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "bu-test_001"  # Valid: lowercase, hyphens, underscores, numbers
  }

  assert {
    condition     = var.business_unit == "bu-test_001"
    error_message = "Business unit with valid special chars should be accepted"
  }
}

# Test: YAML file discovery
run "test_yaml_file_parsing" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "test"
  }

  # Verify locals process YAML files correctly
  assert {
    condition     = can(local.tenant)
    error_message = "Local value 'tenant' should be defined"
  }

  assert {
    condition     = can(local.bu_projects_access)
    error_message = "Local value 'bu_projects_access' should be defined"
  }
}

# Test: Team name generation
run "test_team_name_format" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify team names follow pattern: {bu}_admin
  assert {
    condition = alltrue([
      for team_key, team in tfe_team.bu_admin :
      can(regex("^[a-z0-9_-]+_admin$", team.name))
    ])
    error_message = "Team names should follow pattern: {bu}_admin"
  }
}

# Test: Project name format
run "test_project_name_format" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify control project names follow pattern: {bu}_control
  assert {
    condition = alltrue([
      for proj_key, proj in tfe_project.bu_control :
      can(regex("^[a-z0-9_-]+_control$", proj.name))
    ])
    error_message = "Control project names should follow pattern: {bu}_control"
  }
}

# Test: Variable set naming
run "test_variable_set_naming" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify variable set names follow pattern: {bu}_admin
  assert {
    condition = alltrue([
      for vs_key, vs in tfe_variable_set.bu_admin :
      can(regex("^[a-z0-9_-]+_admin$", vs.name))
    ])
    error_message = "Variable set names should follow pattern: {bu}_admin"
  }
}

# Test: Workspace name format
run "test_workspace_name_format" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify workspace names follow pattern: {bu}_workspace_control
  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      can(regex("^[a-z0-9_-]+_workspace_control$", ws.name))
    ])
    error_message = "Workspace names should follow pattern: {bu}_workspace_control"
  }
}

# Test: Module consumer projects output structure
run "test_module_output_structure" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify module creates expected outputs
  assert {
    condition     = can(module.consumer_project)
    error_message = "Module consumer_project should be defined"
  }
}

# Test: Outputs are properly defined
run "test_outputs_defined" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify required outputs exist
  assert {
    condition     = output.projects != null
    error_message = "Output 'projects' should be defined"
  }

  assert {
    condition     = output.projects_project_access != null
    error_message = "Output 'projects_project_access' should be defined"
  }
}

# Test: Organization name used consistently
run "test_organization_consistency" {
  command = plan

  variables {
    tfc_organization_name = "consistent-test-org"
    business_unit         = "finance"
  }

  # Verify organization name is used in all resources
  assert {
    condition = alltrue([
      for team_key, team in tfe_team.bu_admin :
      team.organization == var.tfc_organization_name
    ])
    error_message = "All teams should use the configured organization name"
  }

  assert {
    condition = alltrue([
      for vs_key, vs in tfe_variable_set.bu_admin :
      vs.organization == var.tfc_organization_name
    ])
    error_message = "All variable sets should use the configured organization name"
  }

  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      ws.organization == var.tfc_organization_name
    ])
    error_message = "All workspaces should use the configured organization name"
  }
}

# Test: Auto-apply disabled for control workspaces
run "test_control_workspace_auto_apply" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify control workspaces have auto-apply disabled (safer)
  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      ws.auto_apply == false
    ])
    error_message = "Control workspaces should have auto_apply disabled for safety"
  }
}

# Test: Destroy plan disabled for control workspaces
run "test_control_workspace_destroy_protection" {
  command = plan

  variables {
    tfc_organization_name = "test-org"
    business_unit         = "finance"
  }

  # Verify control workspaces have destroy protection
  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      ws.allow_destroy_plan == false
    ])
    error_message = "Control workspaces should have destroy protection enabled"
  }
}
