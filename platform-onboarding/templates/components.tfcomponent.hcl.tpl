# ============================================================================
# BU Onboarding Component
# ============================================================================

component "bu_onboarding" {
  source = "app.terraform.io/${organization}/bu-onboarding/tfe"
  
  # Module will be published to Private Module Registry
  # Version constraint will be added once module is published
  # version = "~> 1.0"
  
  inputs = {
    # Organization and project
    tfc_organization_name = var.tfc_organization_name
    bu_project_id         = var.bu_project_id
    
    # Business unit filter
    business_unit = var.business_unit
    
    # VCS integration
    vcs_oauth_token_id = var.vcs_oauth_token_id
    
    # Environment tagging
    environment = var.environment
  }
  
  providers = {
    tfe = provider.tfe.this
  }
}
