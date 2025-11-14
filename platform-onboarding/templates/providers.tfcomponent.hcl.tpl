# ============================================================================
# Required Providers
# ============================================================================

required_providers {
  tfe = {
    source  = "hashicorp/tfe"
    version = "~> 0.60"
  }
}

# ============================================================================
# TFE Provider Configuration with OIDC
# ============================================================================

provider "tfe" "this" {
  config {
    hostname = "app.terraform.io"
    
    # OIDC Authentication
    token = var.tfe_identity_token
  }
}
