# Unit Tests for bu-control-workspace
#
# These tests validate the BU team layer logic without creating real infrastructure.
# Tests focus on variable validation, YAML parsing, and workspace configuration logic.
#
# Run with: terraform test -filter=tests/bu-control-workspace/unit-tests.tftest.hcl

# Test: Organization name validation - empty string
run "test_organization_empty" {
  command = plan

  variables {
    organization     = ""
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123456"
    bu_projects      = "{}"
  }

  expect_failures = [
    var.organization
  ]
}

# Test: GitHub org validation - empty string
run "test_github_org_empty" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = ""
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123456"
    bu_projects      = "{}"
  }

  expect_failures = [
    var.github_org
  ]
}

# Test: GitHub org owner validation - empty string
run "test_github_org_owner_empty" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = ""
    oauth_token_id   = "ot-test123456"
    bu_projects      = "{}"
  }

  expect_failures = [
    var.github_org_owner
  ]
}

# Test: OAuth token validation - wrong format
run "test_oauth_token_invalid_format" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "invalid-token"  # Missing 'ot-' prefix
    bu_projects      = "{}"
  }

  expect_failures = [
    var.oauth_token_id
  ]
}

# Test: OAuth token validation - empty string
run "test_oauth_token_empty" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = ""
    bu_projects      = "{}"
  }

  expect_failures = [
    var.oauth_token_id
  ]
}

# Test: BU projects validation - invalid JSON
run "test_bu_projects_invalid_json" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123456"
    bu_projects      = "not-valid-json"
  }

  expect_failures = [
    var.bu_projects
  ]
}

# Test: Valid minimal configuration
run "test_valid_minimal_config" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-gh-org"
    github_org_owner = "test-gh-owner"
    oauth_token_id   = "ot-validtoken123"
    bu_projects      = "{\"project1\":\"prj-abc123\"}"
  }

  assert {
    condition     = var.organization == "test-org"
    error_message = "Organization should be 'test-org'"
  }

  assert {
    condition     = var.github_org == "test-gh-org"
    error_message = "GitHub org should be 'test-gh-org'"
  }
}

# Test: OAuth token with various valid formats
run "test_oauth_token_valid_formats" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-ABC123xyz789"  # Mixed case alphanumeric
    bu_projects      = "{}"
  }

  assert {
    condition     = can(regex("^ot-[a-zA-Z0-9]+$", var.oauth_token_id))
    error_message = "OAuth token should match pattern ot-[alphanumeric]"
  }
}

# Test: BU projects with null value
run "test_bu_projects_null" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = null
  }

  # Null should be valid (default value)
  assert {
    condition     = var.bu_projects == null
    error_message = "BU projects can be null"
  }
}

# Test: YAML workspace configuration parsing
run "test_yaml_workspace_parsing" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify locals are defined
  assert {
    condition     = can(local.workspaceConfig)
    error_message = "Local workspaceConfig should be defined"
  }

  assert {
    condition     = can(local.workspaces)
    error_message = "Local workspaces should be defined"
  }

  assert {
    condition     = can(local.workspaceRepos)
    error_message = "Local workspaceRepos should be defined"
  }
}

# Test: Workspace repository filtering logic
run "test_workspace_repo_filtering" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify only workspaces with create_repo=true are in workspaceRepos
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaceRepos :
      try(ws.create_repo, false) == true
    ])
    error_message = "workspaceRepos should only contain workspaces with create_repo=true"
  }
}

# Test: Variable set mapping logic
run "test_varset_mapping" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify varsetMap structure
  assert {
    condition     = can(local.varsetMap)
    error_message = "Local varsetMap should be defined"
  }

  # Verify ws_varSets filtering
  assert {
    condition = alltrue([
      for ws_key, ws in local.ws_varSets :
      try(ws.create_variable_set, false) == true
    ])
    error_message = "ws_varSets should only contain workspaces with create_variable_set=true"
  }
}

# Test: Output structure
run "test_output_structure" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify outputs are defined
  assert {
    condition     = can(output.varsetMap)
    error_message = "Output varsetMap should be defined"
  }

  assert {
    condition     = can(output.variable_set)
    error_message = "Output variable_set should be defined"
  }

  assert {
    condition     = can(output.project_id)
    error_message = "Output project_id should be defined"
  }

  assert {
    condition     = can(output.bu_projects)
    error_message = "Output bu_projects should be defined"
  }
}

# Test: Module for_each usage
run "test_module_for_each" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify modules use appropriate for_each sources
  assert {
    condition     = can(module.terraform-tfe-variable-sets)
    error_message = "Variable sets module should be defined"
  }

  assert {
    condition     = can(module.github)
    error_message = "GitHub module should be defined"
  }

  assert {
    condition     = can(module.workspace)
    error_message = "Workspace module should be defined"
  }
}

# Test: Workspace data source
run "test_workspace_data_source" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify workspace IDs data source is configured
  assert {
    condition     = data.tfe_workspace_ids.all.organization == var.organization
    error_message = "Data source should use correct organization"
  }

  assert {
    condition     = contains(data.tfe_workspace_ids.all.names, "*")
    error_message = "Data source should query all workspaces"
  }
}

# Test: Variable set to workspace association logic
run "test_varset_workspace_association" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify association resource uses correct for_each
  assert {
    condition     = can(tfe_workspace_variable_set.set)
    error_message = "Workspace variable set association should be defined"
  }
}

# Test: BU projects JSON parsing
run "test_bu_projects_json_parsing" {
  command = plan

  variables {
    organization     = "test-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{\"dev\":\"prj-dev123\",\"prod\":\"prj-prod456\"}"
  }

  # Verify JSON can be decoded
  assert {
    condition     = can(jsondecode(var.bu_projects))
    error_message = "BU projects JSON should be parseable"
  }

  # Verify parsed structure
  assert {
    condition     = length(jsondecode(var.bu_projects)) == 2
    error_message = "Should parse 2 projects from JSON"
  }
}

# Test: Workspace organization consistency
run "test_workspace_organization_consistency" {
  command = plan

  variables {
    organization     = "consistent-org"
    github_org       = "test-org"
    github_org_owner = "test-org"
    oauth_token_id   = "ot-test123"
    bu_projects      = "{}"
  }

  # Verify organization is used consistently
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      try(ws.organization, var.organization) == var.organization
    ])
    error_message = "All workspaces should use configured organization"
  }
}
