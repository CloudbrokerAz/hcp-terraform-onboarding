# ============================================================================
# Core Outputs - TFC Resources
# ============================================================================

output "organization_name" {
  description = "HCP Terraform organization name"
  value       = var.tfc_organization_name
}

output "business_units" {
  description = "List of business units managed by this module"
  value       = keys(local.tenant)
}

# ============================================================================
# BU Project Outputs (Optimized for publish_output)
# ============================================================================

output "bu_project_ids_map" {
  description = "Map of BU names to control project IDs for upstream consumption"
  value = {
    for bu, config in local.tenant : 
    bu => tfe_project.bu_control[bu].id
  }
}

output "bu_project_names_map" {
  description = "Map of BU names to control project names"
  value = {
    for bu, config in local.tenant : 
    bu => tfe_project.bu_control[bu].name
  }
}

output "consumer_project_ids_map" {
  description = "Map of BU consumer project IDs (bu_project format)"
  value = {
    for key, proj in tfe_project.consumer :
    key => proj.id
  }
}

# ============================================================================
# Team and Token Outputs
# ============================================================================

output "bu_admin_team_ids_map" {
  description = "Map of BU names to admin team IDs"
  value = {
    for bu, team in tfe_team.bu_admin :
    bu => team.id
  }
}

output "bu_admin_tokens" {
  description = "Map of BU names to admin team tokens (sensitive)"
  value = {
    for bu, token in tfe_team_token.bu_admin :
    bu => token.token
  }
  sensitive = true
}

# ============================================================================
# Workspace Outputs
# ============================================================================

output "bu_control_workspace_ids_map" {
  description = "Map of BU names to control workspace IDs"
  value = {
    for bu, ws in tfe_workspace.bu_control :
    bu => ws.id
  }
}

output "bu_control_workspace_names_map" {
  description = "Map of BU names to control workspace names"
  value = {
    for bu, ws in tfe_workspace.bu_control :
    bu => ws.name
  }
}

# ============================================================================
# Variable Set Outputs
# ============================================================================

output "bu_variable_set_ids_map" {
  description = "Map of BU names to variable set IDs"
  value = {
    for bu, vs in tfe_variable_set.bu_admin :
    bu => vs.id
  }
}

# ============================================================================
# GitHub Repository Outputs (if created)
# ============================================================================

output "bu_stack_repo_names" {
  description = "Map of BU names to Stack repository names in GitHub"
  value = var.create_bu_repositories ? {
    for bu, repo in github_repository.bu_stack :
    bu => repo.name
  } : {}
}

output "bu_stack_repo_urls" {
  description = "Map of BU names to Stack repository HTML URLs"
  value = var.create_bu_repositories ? {
    for bu, repo in github_repository.bu_stack :
    bu => repo.html_url
  } : {}
}

output "bu_stack_clone_urls" {
  description = "Map of BU names to Stack repository clone URLs (SSH)"
  value = var.create_bu_repositories ? {
    for bu, repo in github_repository.bu_stack :
    bu => repo.ssh_clone_url
  } : {}
}

# output "bu_github_team_ids" {
#   description = "Map of BU names to GitHub admin team IDs"
#   value = var.create_bu_repositories ? {
#     for bu, team in github_team.bu_admin :
#     bu => team.id
#   } : {}
# }

# ============================================================================
# Structured Output for Downstream Consumption
# ============================================================================

output "bu_infrastructure" {
  description = "Complete infrastructure mapping per BU (for Stacks publish_output)"
  value = {
    for bu, config in local.tenant : bu => {
      # TFC Resources
      organization     = var.tfc_organization_name
      project_id       = tfe_project.bu_control[bu].id
      project_name     = tfe_project.bu_control[bu].name
      team_id          = tfe_team.bu_admin[bu].id
      workspace_id     = tfe_workspace.bu_control[bu].id
      workspace_name   = tfe_workspace.bu_control[bu].name
      variable_set_id  = tfe_variable_set.bu_admin[bu].id
      
      # GitHub Resources (if created)
      github_repo_name = var.create_bu_repositories ? github_repository.bu_stack[bu].name : null
      github_repo_url  = var.create_bu_repositories ? github_repository.bu_stack[bu].html_url : null
      # github_team_id   = var.create_bu_repositories ? github_team.bu_admin[bu].id : null
      
      # Consumer Projects
      consumer_projects = {
        for proj_key, proj in tfe_project.consumer :
        proj_key => {
          id   = proj.id
          name = proj.name
        } if startswith(proj_key, "${bu}_")
      }
    }
  }
}

# ============================================================================
# Deployment Summary
# ============================================================================

output "deployment_summary" {
  description = "Summary of resources created"
  value = {
    business_units_count         = length(local.tenant)
    bu_projects_count            = length(tfe_project.bu_control)
    consumer_projects_count      = length(tfe_project.consumer)
    bu_teams_count               = length(tfe_team.bu_admin)
    bu_workspaces_count          = length(tfe_workspace.bu_control)
    github_repos_created         = var.create_bu_repositories ? length(github_repository.bu_stack) : 0
    # github_teams_created         = var.create_bu_repositories ? length(github_team.bu_admin) : 0
  }
}
