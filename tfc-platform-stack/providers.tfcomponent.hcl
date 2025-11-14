# ============================================================================
# Required Providers
# ============================================================================

required_providers {
  tfe = {
    source  = "hashicorp/tfe"
    version = "~> 0.60"
  }
  github = {
    source  = "integrations/github"
    version = "~> 6.0"
  }
}

# ============================================================================
# TFE Provider with OIDC Authentication
# ============================================================================

provider "tfe" "this" {
  config {
    hostname = "app.terraform.io"
    
    # OIDC Authentication with platform.onboarding audience
    token = var.tfe_identity_token
  }
}

# ============================================================================
# GitHub Provider
# ============================================================================

provider "github" "this" {
  config {
    owner = var.github_organization
    token = var.github_token
  }
}
