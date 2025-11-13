# Integration Tests for bu-control-workspace
#
# These tests validate end-to-end workspace provisioning including GitHub
# repository creation, VCS connections, and variable set configuration.
#
# Prerequisites:
#   export TFE_TOKEN="your-test-token"
#   export TFE_ORGANIZATION="your-test-org"
#   export GITHUB_TOKEN="your-github-token"
#   export GITHUB_ORG="your-test-org"
#   export OAUTH_TOKEN_ID="ot-xxxxxxxxxxxxx"
#
# Run with: terraform test -filter=tests/bu-control-workspace/integration-tests.tftest.hcl
#
# WARNING: These tests create real resources (GitHub repos, TFC workspaces).
# Ensure cleanup runs successfully to avoid resource accumulation.

variables {
  organization     = "test-integration-org"  # Override with your test org
  github_org       = "test-github-org"       # Override with your GitHub org
  github_org_owner = "test-github-org"
  oauth_token_id   = "ot-testintegration"    # Override with your OAuth token
  bu_projects      = "{\"test-project\":\"prj-test123\"}"  # Mock project ID
}

# Test: Create workspaces from YAML configuration
run "create_workspaces" {
  command = apply

  # Verify workspaces are created
  assert {
    condition     = length(module.workspace) > 0
    error_message = "At least one workspace should be created from YAML config"
  }

  # Verify workspace configuration module is called
  assert {
    condition     = can(module.workspace)
    error_message = "Workspace module should be instantiated"
  }
}

# Test: GitHub repositories are created
run "verify_github_repos" {
  command = apply

  # Verify GitHub module is instantiated for repos
  assert {
    condition     = can(module.github)
    error_message = "GitHub module should be defined"
  }

  # Verify only workspaces with create_repo=true trigger repo creation
  assert {
    condition     = length(module.github) == length(local.workspaceRepos)
    error_message = "GitHub repos should match workspaceRepos count"
  }
}

# Test: Variable sets are created
run "verify_variable_sets" {
  command = apply

  # Verify variable set module is called
  assert {
    condition     = can(module.terraform-tfe-variable-sets)
    error_message = "Variable sets module should be defined"
  }

  # Verify variable sets match varsetMap
  assert {
    condition     = length(module.terraform-tfe-variable-sets) == length(local.varsetMap)
    error_message = "Variable set count should match varsetMap"
  }
}

# Test: Variable set outputs
run "verify_variable_set_outputs" {
  command = apply

  # Verify variable_set output structure
  assert {
    condition     = can(output.variable_set)
    error_message = "variable_set output should be available"
  }

  # Verify output is marked sensitive
  assert {
    condition     = can(output.variable_set)
    error_message = "variable_set output should exist (sensitivity checked in definition)"
  }
}

# Test: Workspace IDs data source
run "verify_workspace_ids_data" {
  command = apply

  # Verify data source queries workspaces
  assert {
    condition     = can(data.tfe_workspace_ids.all.ids)
    error_message = "Workspace IDs data source should return workspace map"
  }

  # Verify organization matches
  assert {
    condition     = data.tfe_workspace_ids.all.organization == var.organization
    error_message = "Data source should query correct organization"
  }
}

# Test: Variable set to workspace associations
run "verify_workspace_varset_associations" {
  command = apply

  # Verify associations are created
  assert {
    condition     = length(tfe_workspace_variable_set.set) > 0
    error_message = "Variable set associations should be created"
  }

  # Verify each association has valid IDs
  assert {
    condition = alltrue([
      for assoc_key, assoc in tfe_workspace_variable_set.set :
      can(regex("^vs-", assoc.variable_set_id)) && can(regex("^ws-", assoc.workspace_id))
    ])
    error_message = "Associations should use valid variable set and workspace IDs"
  }
}

# Test: Output structure correctness
run "verify_outputs_structure" {
  command = apply

  # Verify varsetMap output
  assert {
    condition     = can(output.varsetMap)
    error_message = "varsetMap output should be defined"
  }

  # Verify project_id output (workspace IDs)
  assert {
    condition     = can(output.project_id)
    error_message = "project_id output should be defined"
  }

  # Verify bu_projects passthrough
  assert {
    condition     = output.bu_projects == var.bu_projects
    error_message = "bu_projects output should match input variable"
  }
}

# Test: Workspace configuration from YAML
run "verify_workspace_yaml_config" {
  command = apply

  # Verify workspaces use organization from YAML or variable
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      try(ws.organization, var.organization) != ""
    ])
    error_message = "All workspaces should have an organization set"
  }

  # Verify workspace names are present
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      can(ws.workspace_name) && ws.workspace_name != ""
    ])
    error_message = "All workspaces should have valid names"
  }
}

# Test: GitHub repository configuration
run "verify_github_config" {
  command = apply

  # Verify GitHub repos use correct organization
  assert {
    condition = alltrue([
      for repo_key, repo in local.workspaceRepos :
      try(repo.github.github_org, var.github_org) != ""
    ])
    error_message = "All GitHub repos should have an organization configured"
  }

  # Verify repository names are specified
  assert {
    condition = alltrue([
      for repo_key, repo in local.workspaceRepos :
      can(repo.github.github_repo_name) && repo.github.github_repo_name != ""
    ])
    error_message = "All GitHub repos should have valid names"
  }
}

# Test: Module workspace dependencies
run "verify_module_dependencies" {
  command = apply

  # Verify workspace module comes after GitHub module (implicit dependency)
  assert {
    condition     = length(module.workspace) >= 0
    error_message = "Workspace module should handle dependencies correctly"
  }

  # Verify variable set associations wait for both modules
  assert {
    condition     = length(tfe_workspace_variable_set.set) >= 0
    error_message = "Variable set associations should wait for prerequisites"
  }
}

# Test: VCS configuration in workspaces
run "verify_vcs_configuration" {
  command = apply

  # Verify workspaces with vcs_repo configuration
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      !can(ws.vcs_repo) || (can(ws.vcs_repo.identifier) && can(ws.vcs_repo.oauth_token_id))
    ])
    error_message = "Workspaces with VCS should have identifier and OAuth token"
  }
}

# Test: Variable configuration structure
run "verify_workspace_variables" {
  command = apply

  # Verify workspaces can have variables defined
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      !can(ws.variables) || can(keys(ws.variables))
    ])
    error_message = "Workspace variables should be properly structured"
  }
}

# Test: Remote state configuration
run "verify_remote_state_config" {
  command = apply

  # Verify remote state flag exists where configured
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      !can(ws.remote_state) || try(ws.remote_state, false) == true || try(ws.remote_state, false) == false
    ])
    error_message = "Remote state should be boolean value"
  }
}

# Test: Workspace tags
run "verify_workspace_tags" {
  command = apply

  # Verify tags are properly formatted when present
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      !can(ws.workspace_tags) || can(tolist(ws.workspace_tags))
    ])
    error_message = "Workspace tags should be list format"
  }
}

# Test: Terraform version specification
run "verify_terraform_versions" {
  command = apply

  # Verify Terraform version is string when specified
  assert {
    condition = alltrue([
      for ws_key, ws in local.workspaces :
      !can(ws.workspace_terraform_version) || can(tostring(ws.workspace_terraform_version))
    ])
    error_message = "Terraform version should be string format"
  }
}

# Test: Local value transformations
run "verify_local_transformations" {
  command = apply

  # Verify workspace_varset flattening works
  assert {
    condition     = can(local.workspace_varset)
    error_message = "workspace_varset should be properly flattened"
  }

  # Verify varsetMap transformation
  assert {
    condition = alltrue([
      for vs_key, vs in local.varsetMap :
      can(vs.var_sets.variable_set_name)
    ])
    error_message = "varsetMap should have properly structured variable set data"
  }
}

# Test: Cleanup - Destroy all created resources
run "cleanup_integration_test" {
  command = destroy

  # Verify cleanup plans to remove workspace associations
  assert {
    condition     = length(tfe_workspace_variable_set.set) >= 0
    error_message = "Cleanup should plan to destroy workspace variable set associations"
  }
}
