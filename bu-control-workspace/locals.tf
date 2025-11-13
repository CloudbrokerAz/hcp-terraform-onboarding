# Local values for workspace configuration processing
locals {
  # Read YAML files and handle empty/commented files gracefully
  workspaceConfig = flatten([
    for workspace in fileset(path.module, "config/*.yaml") :
    try(yamldecode(file(workspace)), [])
  ])

  # Filter out empty objects/lists and ensure valid workspace configurations
  workspaces = {
    for workspace in local.workspaceConfig :
    workspace.workspace_name => workspace
    if can(workspace.workspace_name)
  }

  # Filter workspaces to only those that need a new GitHub repo created
  workspaceRepos = {
    for workspace in local.workspaceConfig :
    workspace.workspace_name => workspace
    if can(workspace.workspace_name) && try(workspace.create_repo, false)
  }

  # Filter workspaces to only those with variable sets
  ws_varSets = {
    for workspace in local.workspaceConfig :
    workspace.workspace_name => workspace
    if can(workspace.workspace_name) && try(workspace.create_variable_set, false)
  }

  # Loop through each workspace, then each varset and flatten
  workspace_varset = flatten([
    for key, value in local.ws_varSets : [
      for varset in value["var_sets"] :
      {
        organization        = value["organization"]
        workspace_name      = value["workspace_name"]
        create_variable_set = value["create_variable_set"]
        var_sets            = varset
      }
    ]
  ])

  # Convert to a Map with variable set name as key
  varsetMap = {
    for varset in local.workspace_varset :
    varset.var_sets.variable_set_name => varset
  }
}
