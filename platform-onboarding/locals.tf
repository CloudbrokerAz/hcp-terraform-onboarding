# Read YAML configuration files
locals {
  # Read all YAML files in config/ directory
  config_file = flatten([
    for tenant_file in fileset(path.module, "config/*.yaml") : 
    try(yamldecode(file("${path.module}/${tenant_file}")), [])
  ])
  
  # Filter to create tenant map, optionally filtering by business_unit variable
  tenant = var.business_unit != null ? {
    for bu in local.config_file : bu.bu => bu 
    if can(bu.bu) && bu.bu == var.business_unit
  } : {
    for bu in local.config_file : bu.bu => bu 
    if can(bu.bu)
  }
  
  # Flatten project list for easier processing
  bu_project_list = flatten([
    for bu_key, bu_value in local.tenant : [
      for project_key, project_value in try(bu_value.projects, {}) : {
        "${bu_key}_${project_key}" = {
          bu      = bu_key
          project = project_key
          value   = project_value
        }
      }
    ]
  ])
  
  # Convert list to map for easier lookups
  bu_projects_access = {
    for bu_project in local.bu_project_list : 
    keys(bu_project)[0] => values(bu_project)[0]
  }
}
