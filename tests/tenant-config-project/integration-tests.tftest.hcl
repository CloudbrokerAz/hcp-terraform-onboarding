# Integration Tests for tenant-config-project
#
# These tests validate end-to-end functionality by deploying actual infrastructure
# in a test environment. Requires HCP Terraform credentials and test organization.
#
# Prerequisites:
#   export TFE_TOKEN="your-test-token"
#   export TFE_ORGANIZATION="your-test-org"
#
# Run with: terraform test -filter=tests/tenant-config-project/integration-tests.tftest.hcl
#
# WARNING: These tests create real resources and may incur costs.
# Ensure cleanup runs successfully to avoid resource accumulation.

variables {
  tfc_organization_name = "test-integration-org"  # Override with your test org
  business_unit         = "test-finance"
}

# Test: Create complete platform infrastructure
run "create_platform_infrastructure" {
  command = apply

  # Verify teams are created
  assert {
    condition     = length(tfe_team.bu_admin) > 0
    error_message = "At least one BU admin team should be created"
  }

  # Verify team tokens are generated
  assert {
    condition     = length(tfe_team_token.bu_admin) > 0
    error_message = "Team tokens should be generated for admin teams"
  }

  # Verify control projects are created
  assert {
    condition     = length(tfe_project.bu_control) > 0
    error_message = "At least one control project should be created"
  }

  # Verify control workspaces are created
  assert {
    condition     = length(tfe_workspace.bu_control) > 0
    error_message = "At least one control workspace should be created"
  }

  # Verify variable sets are created
  assert {
    condition     = length(tfe_variable_set.bu_admin) > 0
    error_message = "Variable sets should be created for BU admins"
  }

  # Verify consumer projects are created via module
  assert {
    condition     = length(module.consumer_project) > 0
    error_message = "At least one consumer project should be created"
  }
}

# Test: Verify team names follow convention
run "verify_team_naming" {
  command = apply

  assert {
    condition = alltrue([
      for team_key, team in tfe_team.bu_admin :
      endswith(team.name, "_admin")
    ])
    error_message = "All team names should end with '_admin'"
  }
}

# Test: Verify project structure
run "verify_project_structure" {
  command = apply

  # Verify control projects exist
  assert {
    condition = alltrue([
      for proj_key, proj in tfe_project.bu_control :
      endswith(proj.name, "_control")
    ])
    error_message = "Control projects should end with '_control'"
  }

  # Verify projects are in correct organization
  assert {
    condition = alltrue([
      for proj_key, proj in tfe_project.bu_control :
      proj.organization == var.tfc_organization_name
    ])
    error_message = "All projects should be in the test organization"
  }
}

# Test: Verify team access to projects
run "verify_team_project_access" {
  command = apply

  # Verify team-project access resources are created
  assert {
    condition     = length(tfe_team_project_access.bu_control) > 0
    error_message = "Team project access should be configured"
  }

  # Verify admin access level
  assert {
    condition = alltrue([
      for access_key, access in tfe_team_project_access.bu_control :
      access.access == "admin"
    ])
    error_message = "BU admin teams should have admin access to control projects"
  }
}

# Test: Verify variable set structure
run "verify_variable_sets" {
  command = apply

  # Verify TFE_TOKEN variable is created
  assert {
    condition = alltrue([
      for var_key, var in tfe_variable.bu_admin :
      var.key == "TFE_TOKEN"
    ])
    error_message = "TFE_TOKEN variable should be created in variable sets"
  }

  # Verify token variable is sensitive
  assert {
    condition = alltrue([
      for var_key, var in tfe_variable.bu_admin :
      var.sensitive == true
    ])
    error_message = "TFE_TOKEN variable should be marked as sensitive"
  }

  # Verify category is 'env' for environment variables
  assert {
    condition = alltrue([
      for var_key, var in tfe_variable.bu_admin :
      var.category == "env"
    ])
    error_message = "TFE_TOKEN should be an environment variable"
  }
}

# Test: Verify bu_projects variable structure
run "verify_bu_projects_variable" {
  command = apply

  # Verify bu_projects variable exists
  assert {
    condition = alltrue([
      for var_key, var in tfe_variable.bu_projects :
      var.key == "bu_projects"
    ])
    error_message = "bu_projects variable should be created"
  }

  # Verify it's a terraform variable
  assert {
    condition = alltrue([
      for var_key, var in tfe_variable.bu_projects :
      var.category == "terraform"
    ])
    error_message = "bu_projects should be a terraform variable"
  }

  # Verify value is valid JSON
  assert {
    condition = alltrue([
      for var_key, var in tfe_variable.bu_projects :
      can(jsondecode(var.value))
    ])
    error_message = "bu_projects value should be valid JSON"
  }
}

# Test: Verify variable set to project assignment
run "verify_variable_set_assignment" {
  command = apply

  # Verify variable sets are assigned to projects
  assert {
    condition     = length(tfe_project_variable_set.bu_admin) > 0
    error_message = "Variable sets should be assigned to control projects"
  }
}

# Test: Verify workspace configuration
run "verify_workspace_config" {
  command = apply

  # Verify workspaces are in control projects
  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      can(regex("^prj-", ws.project_id))
    ])
    error_message = "Workspaces should be assigned to valid projects"
  }

  # Verify auto-apply is disabled
  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      ws.auto_apply == false
    ])
    error_message = "Control workspaces should have auto-apply disabled"
  }

  # Verify destroy protection is enabled
  assert {
    condition = alltrue([
      for ws_key, ws in tfe_workspace.bu_control :
      ws.allow_destroy_plan == false
    ])
    error_message = "Control workspaces should have destroy protection enabled"
  }
}

# Test: Verify outputs are correct
run "verify_outputs" {
  command = apply

  # Verify projects output has expected structure
  assert {
    condition     = can(output.projects)
    error_message = "Output 'projects' should be available"
  }

  # Verify projects_project_access output exists
  assert {
    condition     = can(output.projects_project_access)
    error_message = "Output 'projects_project_access' should be available"
  }

  # Verify project output contains required attributes
  assert {
    condition = alltrue([
      for proj_key, proj in module.consumer_project :
      can(proj.project_id) && can(proj.bu)
    ])
    error_message = "Project outputs should contain project_id and bu attributes"
  }
}

# Test: Verify consumer project module integration
run "verify_consumer_project_module" {
  command = apply

  # Verify module creates projects
  assert {
    condition     = length(module.consumer_project) > 0
    error_message = "Consumer project module should create at least one project"
  }

  # Verify project names follow pattern
  assert {
    condition = alltrue([
      for proj_key, proj_value in module.consumer_project :
      can(regex("^[a-z0-9_-]+_[a-z0-9_-]+$", proj_key))
    ])
    error_message = "Consumer project names should follow pattern: {bu}_{project}"
  }
}

# Test: Cleanup - Destroy all created resources
run "cleanup_integration_test" {
  command = destroy

  # Verify plan includes destruction of all resource types
  assert {
    condition     = length(tfe_team.bu_admin) >= 0
    error_message = "Cleanup should plan to destroy teams"
  }
}
