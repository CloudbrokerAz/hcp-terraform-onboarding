variable "tfc_organization_name" {
  type        = string
  description = "HCP Terraform organization name where platform infrastructure will be created"

  validation {
    condition     = length(var.tfc_organization_name) > 0 && length(var.tfc_organization_name) <= 255
    error_message = "Organization name must be between 1 and 255 characters."
  }
}

variable "business_unit" {
  type        = string
  description = "Business unit identifier filter (optional). If specified, only this BU will be processed. Leave null to process all BUs from YAML configs."
  default     = null

  validation {
    condition     = var.business_unit == null || can(regex("^[a-z0-9_-]+$", var.business_unit))
    error_message = "Business unit must be null or a string containing only lowercase letters, numbers, underscores, and hyphens."
  }
}

# GitHub repository configuration
variable "create_bu_repositories" {
  type        = bool
  description = "Whether to create GitHub repositories for BU Stacks. Set to false to skip repository creation."
  default     = true
}

variable "github_organization" {
  type        = string
  description = "GitHub organization where BU Stack repositories will be created"
  default     = ""
}

variable "bu_stack_template_repo" {
  type        = string
  description = "Template repository for BU Stack initialization (format: owner/repo). Leave empty to create repos without template."
  default     = ""
}

variable "bu_stack_repo_prefix" {
  type        = string
  description = "Prefix for BU Stack repository names (e.g., 'tfc' results in 'tfc-finance-bu-stack')"
  default     = "tfc"
}

variable "bu_stack_repo_suffix" {
  type        = string
  description = "Suffix for BU Stack repository names"
  default     = "bu-stack"
}

# HCP Terraform Stack configuration
variable "create_hcp_stacks" {
  type        = bool
  description = "Whether to create HCP Terraform Stacks for each BU. Requires OAuth token configuration."
  default     = false
}

variable "vcs_oauth_token_id" {
  type        = string
  description = "OAuth token ID for VCS connection to GitHub. Required if create_hcp_stacks = true."
  default     = ""
}

variable "platform_stack_project" {
  type        = string
  description = "HCP Terraform project name where platform stack resides (for BU Stack upstream_input references)"
  default     = "Platform_Team"
}

# GitHub team and access configuration
variable "github_team_privacy" {
  type        = string
  description = "Privacy level for GitHub teams (closed or secret)"
  default     = "closed"
  
  validation {
    condition     = contains(["closed", "secret"], var.github_team_privacy)
    error_message = "GitHub team privacy must be either 'closed' or 'secret'."
  }
}

variable "enable_branch_protection" {
  type        = bool
  description = "Whether to enable branch protection on BU Stack repositories"
  default     = true
}

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
# YAML Configuration Input
# ============================================================================

variable "yaml_config_content" {
  type        = string
  description = "YAML configuration file content. The Stack will read config/*.yaml files and pass content to this variable."
  
  validation {
    condition     = can(yamldecode(var.yaml_config_content))
    error_message = "yaml_config_content must be valid YAML format."
  }
}
