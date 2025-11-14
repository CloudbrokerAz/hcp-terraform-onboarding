# ============================================================================
# Platform Onboarding Component
# ============================================================================

component "platform_onboarding" {
  source  = "app.terraform.io/cloudbrokeraz/platform-onboarding/tfe"
  version = "1.0.0"  # Update after module is published to PMR
  
  inputs = {
    # TFC Organization
    tfc_organization_name = var.tfc_organization_name
    
    # Optional: Filter to single business unit
    business_unit = var.business_unit
    
    # GitHub Repository Creation
    create_bu_repositories = var.create_bu_repositories
    github_organization    = var.github_organization
    bu_stack_repo_prefix   = var.bu_stack_repo_prefix
    bu_stack_repo_suffix   = var.bu_stack_repo_suffix
    
    # HCP Terraform Stacks (managed separately via Stack deployment)
    create_hcp_stacks  = false
    vcs_oauth_token_id = ""
    
    # Platform Configuration
    platform_stack_project = var.platform_project_name
    
    # GitHub Settings
    github_team_privacy      = "closed"
    enable_branch_protection = var.enable_branch_protection
    
    # Commit Author for Seeded Files
    commit_author_name  = var.commit_author_name
    commit_author_email = var.commit_author_email
  }
  
  providers = {
    tfe    = provider.tfe.this
    github = provider.github.this
  }
}
