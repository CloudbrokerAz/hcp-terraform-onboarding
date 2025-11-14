# ============================================================================
# Stack Input Variables
# ============================================================================

variable "tfc_organization_name" {
  type        = string
  description = "HCP Terraform organization name"
  default     = "cloudbrokeraz"
}

variable "github_organization" {
  type        = string
  description = "GitHub organization name"
  default     = "CloudbrokerAz"
}

variable "platform_project_name" {
  type        = string
  description = "Platform team project name in HCP Terraform"
  default     = "Platform_Team"
}

variable "tfe_identity_token" {
  type        = string
  description = "OIDC identity token for TFE provider authentication"
  ephemeral   = true
  sensitive   = true
}

variable "github_token" {
  type        = string
  description = "GitHub personal access token for GitHub provider"
  ephemeral   = true
  sensitive   = true
}

# ============================================================================
# GitHub Repository Configuration
# ============================================================================

variable "create_bu_repositories" {
  type        = bool
  description = "Create GitHub repositories for BU Stacks"
  default     = true
}

variable "bu_stack_repo_prefix" {
  type        = string
  description = "Prefix for BU Stack repository names"
  default     = "tfc"
}

variable "bu_stack_repo_suffix" {
  type        = string
  description = "Suffix for BU Stack repository names"
  default     = "bu-stack"
}

variable "enable_branch_protection" {
  type        = bool
  description = "Enable branch protection on main branch"
  default     = true
}

# ============================================================================
# Commit Configuration
# ============================================================================

variable "commit_author_name" {
  type        = string
  description = "Git commit author name for seeded files"
  default     = "Platform Team"
}

variable "commit_author_email" {
  type        = string
  description = "Git commit author email for seeded files"
  default     = "platform-team@cloudbrokeraz.com"
}

# ============================================================================
# Business Unit Filter (Optional)
# ============================================================================

variable "business_unit" {
  type        = string
  description = "Optional: Filter to single business unit (null = all BUs from YAML)"
  default     = null
}
