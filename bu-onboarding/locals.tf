# ============================================================================
# YAML Configuration Processing
# ============================================================================

locals {
  # Read all YAML files from config/ directory
  workspace_config_files = fileset(path.module, "config/*.yaml")
  
  # Parse YAML files and flatten into single list
  workspace_config_raw = flatten([
    for file in local.workspace_config_files :
    try(yamldecode(file("${path.module}/${file}")), [])
  ])
  
  # Filter by business_unit if specified
  workspace_config_filtered = var.business_unit != null ? [
    for config in local.workspace_config_raw :
    config if try(config.business_unit, "") == var.business_unit
  ] : local.workspace_config_raw
  
  # Create map of workspaces indexed by workspace_name
  workspaces = {
    for workspace in local.workspace_config_filtered :
    workspace.workspace_name => merge(workspace, {
      # Add environment tag
      workspace_tags = concat(
        try(workspace.workspace_tags, []),
        ["environment:${var.environment}"]
      )
    })
    if can(workspace.workspace_name)
  }
  
  # Extract variable sets from workspaces
  workspace_variable_sets_raw = flatten([
    for key, workspace in local.workspaces : [
      for varset in try(workspace.var_sets, []) : {
        workspace_name      = workspace.workspace_name
        organization        = var.tfc_organization_name
        create_variable_set = try(workspace.create_variable_set, false)
        var_sets            = varset
      }
    ] if try(workspace.create_variable_set, false)
  ])
  
  # Create map of variable sets indexed by variable_set_name
  variable_sets = {
    for varset in local.workspace_variable_sets_raw :
    varset.var_sets.variable_set_name => varset
  }
}
