# ============================================================================
# Identity Tokens for OIDC Authentication
# ============================================================================

identity_token "tfe" {
  audience = ["platform.onboarding"]
}

identity_token "github" {
  audience = ["platform.onboarding"]  # Same audience for GitHub operations
}

# ============================================================================
# Local Values
# ============================================================================

locals {
  # Common configuration
  organization        = "cloudbrokeraz"
  github_organization = "CloudbrokerAz"
  platform_project    = "Platform_Team"
  
  # Commit configuration
  commit_author_name  = "Platform Team"
  commit_author_email = "platform-team@cloudbrokeraz.com"
  
  # Repository configuration
  create_bu_repositories   = true
  bu_stack_repo_prefix     = "tfc"
  bu_stack_repo_suffix     = "bu-stack"
  enable_branch_protection = true
}

# ============================================================================
# Deployment: Finance BU
# ============================================================================

deployment "finance" {
  inputs = {
    # Organization
    tfc_organization_name = local.organization
    
    # Filter to finance business unit
    business_unit = "finance"
    
    # OIDC tokens
    tfe_identity_token = identity_token.tfe.jwt
    github_token       = identity_token.github.jwt
    
    # GitHub repository creation
    create_bu_repositories   = local.create_bu_repositories
    github_organization      = local.github_organization
    bu_stack_repo_prefix     = local.bu_stack_repo_prefix
    bu_stack_repo_suffix     = local.bu_stack_repo_suffix
    enable_branch_protection = local.enable_branch_protection
    
    # Platform configuration
    platform_project_name = local.platform_project
    
    # Commit author
    commit_author_name  = local.commit_author_name
    commit_author_email = local.commit_author_email
  }
}

# ============================================================================
# Deployment: Engineering BU
# ============================================================================

deployment "engineering" {
  inputs = {
    # Organization
    tfc_organization_name = local.organization
    
    # Filter to engineering business unit
    business_unit = "engineering"
    
    # OIDC tokens
    tfe_identity_token = identity_token.tfe.jwt
    github_token       = identity_token.github.jwt
    
    # GitHub repository creation
    create_bu_repositories   = local.create_bu_repositories
    github_organization      = local.github_organization
    bu_stack_repo_prefix     = local.bu_stack_repo_prefix
    bu_stack_repo_suffix     = local.bu_stack_repo_suffix
    enable_branch_protection = local.enable_branch_protection
    
    # Platform configuration
    platform_project_name = local.platform_project
    
    # Commit author
    commit_author_name  = local.commit_author_name
    commit_author_email = local.commit_author_email
  }
}

# ============================================================================
# Deployment: Sales BU
# ============================================================================

deployment "sales" {
  inputs = {
    # Organization
    tfc_organization_name = local.organization
    
    # Filter to sales business unit
    business_unit = "sales"
    
    # OIDC tokens
    tfe_identity_token = identity_token.tfe.jwt
    github_token       = identity_token.github.jwt
    
    # GitHub repository creation
    create_bu_repositories   = local.create_bu_repositories
    github_organization      = local.github_organization
    bu_stack_repo_prefix     = local.bu_stack_repo_prefix
    bu_stack_repo_suffix     = local.bu_stack_repo_suffix
    enable_branch_protection = local.enable_branch_protection
    
    # Platform configuration
    platform_project_name = local.platform_project
    
    # Commit author
    commit_author_name  = local.commit_author_name
    commit_author_email = local.commit_author_email
  }
}

