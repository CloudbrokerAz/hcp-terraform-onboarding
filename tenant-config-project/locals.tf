#read each yaml file in ./config/*.yaml
locals {
  config_file = flatten([for tenant in fileset(path.module, "config/*.yaml") : yamldecode(file(tenant))])
  tenant      = { for bu in local.config_file : bu.bu => bu }
  
#flatten the list of projects
  bu_project_list = flatten([
    for bu_key, bu_value in local.tenant : [
      for project_key, project_value in bu_value.projects : {
        "${bu_key}_${project_key}" = {
          bu      = bu_key
          project = project_key
          value   = project_value
        }
      }
    ]
  ])

#filter based on read-outputs
  read_outputs_map = { for key, value in local.bu_projects_access : key => value if length(value.value["read-outputs"]) > 0 }

  # convert list of bu_project_list to map
  bu_projects_access = { for bu_project in local.bu_project_list : keys(bu_project)[0] => values(bu_project)[0] }

# key based on project, team and readaccess to parent project
  read_output_keys = flatten([
    for proj_key, proj_value in local.read_outputs_map : [
      for key, value in proj_value.value.team_project_access : [
        for readaccess_key, readaccess_value in proj_value.value.read-outputs : {
          "${proj_key}_${key}_${readaccess_key}" = {
            bu         = proj_value.bu
            project    = proj_value.value.name
            readaccess = readaccess_value.project
            team ="${proj_key}_${value.team.access}"
            value      = value
          }
        }
      ]
    ]
  ])


}



output "read_output_keys1" {
  value = local.read_output_keys
}

