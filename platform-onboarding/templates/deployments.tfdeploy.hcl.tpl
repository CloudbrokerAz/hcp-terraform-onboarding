# ============================================================================
# Identity Tokens for OIDC Authentication
# ============================================================================

identity_token "tfe" {
  audience = ["${oidc_audience}"]
}

# ============================================================================
# Upstream Stack Reference
# ============================================================================

upstream_input "platform_stack" {
  type   = "stack"
  source = "app.terraform.io/${organization}/${platform_project}/platform-stack"
}

# ============================================================================
# Local Values
# ============================================================================

locals {
  # Extract BU-specific infrastructure from platform stack
  bu_infrastructure = upstream_input.platform_stack.bu_infrastructure["${bu_name}"]
}

# ============================================================================
# Deployment Configurations
# ============================================================================

deployment "dev" {
  inputs = {
    # Organization
    tfc_organization_name = "${organization}"
    
    # Upstream inputs from platform stack
    bu_project_id   = local.bu_infrastructure.project_id
    bu_admin_token  = upstream_input.platform_stack.bu_admin_tokens["${bu_name}"]
    
    # OIDC authentication
    tfe_identity_token = identity_token.tfe.jwt
    
    # VCS integration (requires GitHub token)
    # NOTE: Configure github_token in HCP Terraform variable set
    github_token       = "" # Provided via variable set
    vcs_oauth_token_id = "" # Provided via variable set
    
    # BU context
    business_unit = "${bu_name}"
    environment   = "dev"
  }
}

deployment "staging" {
  inputs = {
    # Organization
    tfc_organization_name = "${organization}"
    
    # Upstream inputs from platform stack
    bu_project_id   = local.bu_infrastructure.project_id
    bu_admin_token  = upstream_input.platform_stack.bu_admin_tokens["${bu_name}"]
    
    # OIDC authentication
    tfe_identity_token = identity_token.tfe.jwt
    
    # VCS integration
    github_token       = "" # Provided via variable set
    vcs_oauth_token_id = "" # Provided via variable set
    
    # BU context
    business_unit = "${bu_name}"
    environment   = "staging"
  }
}

deployment "production" {
  inputs = {
    # Organization
    tfc_organization_name = "${organization}"
    
    # Upstream inputs from platform stack
    bu_project_id   = local.bu_infrastructure.project_id
    bu_admin_token  = upstream_input.platform_stack.bu_admin_tokens["${bu_name}"]
    
    # OIDC authentication
    tfe_identity_token = identity_token.tfe.jwt
    
    # VCS integration
    github_token       = "" # Provided via variable set
    vcs_oauth_token_id = "" # Provided via variable set
    
    # BU context
    business_unit = "${bu_name}"
    environment   = "production"
  }
}
