# ============================================================================
# Parse YAML Configuration
# ============================================================================

locals {
  # Parse YAML content passed from Stack
  yaml_config = yamldecode(var.yaml_config_content)
  
  # Extract business unit identifier
  config_business_unit = try(local.yaml_config.business_unit, null)
  
  # Filter based on business_unit variable (if specified)
  process_this_config = var.business_unit == null || local.config_business_unit == var.business_unit
  
  # Extract projects list (only if business_unit matches)
  bu_projects_raw = local.process_this_config ? try(local.yaml_config.bu_projects, []) : []
  
  # Transform projects into map with BU prefix
  bu_projects = {
    for idx, project in local.bu_projects_raw :
    "${local.config_business_unit}_${project.project_name}" => merge(project, {
      bu           = local.config_business_unit
      project_key  = project.project_name
      full_key     = "${local.config_business_unit}_${project.project_name}"
    })
  }
  
  # Extract workspace list across all projects
  bu_workspaces = flatten([
    for project_key, project in local.bu_projects : [
      for workspace in try(project.bu_workspaces, []) :
      merge(workspace, {
        bu          = local.config_business_unit
        project_key = project.project_name
        full_key    = "${local.config_business_unit}_${project.project_name}_${workspace.workspace_name}"
      })
    ]
  ])
  
  # Create workspace map for easier lookups
  bu_workspaces_map = {
    for ws in local.bu_workspaces :
    ws.full_key => ws
  }
  
  # Summary counts
  projects_count  = length(local.bu_projects)
  workspaces_count = length(local.bu_workspaces)
}
