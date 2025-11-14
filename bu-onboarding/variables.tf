# ============================================================================
# Upstream Inputs (from platform stack)
# ============================================================================

variable "tfc_organization_name" {
  type        = string
  description = "HCP Terraform organization name"
  
  validation {
    condition     = length(var.tfc_organization_name) > 0
    error_message = "Organization name must not be empty."
  }
}

variable "bu_project_id" {
  type        = string
  description = "Business unit control project ID from platform stack"
  
  validation {
    condition     = can(regex("^prj-[a-zA-Z0-9]+$", var.bu_project_id))
    error_message = "Project ID must start with 'prj-' followed by alphanumeric characters."
  }
}

# ============================================================================
# Configuration
# ============================================================================

variable "business_unit" {
  type        = string
  description = "Business unit name (optional filter for YAML configs)"
  default     = null
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, production) - used for tagging"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# ============================================================================
# VCS Integration
# ============================================================================

variable "vcs_oauth_token_id" {
  type        = string
  description = "OAuth token ID for VCS connection (format: ot-xxxxxxxxx)"
  
  validation {
    condition     = can(regex("^ot-[a-zA-Z0-9]+$", var.vcs_oauth_token_id))
    error_message = "OAuth token ID must start with 'ot-' followed by alphanumeric characters."
  }
}

# ============================================================================
# Feature Flags
# ============================================================================

variable "enable_assessments" {
  type        = bool
  description = "Enable drift detection assessments for workspaces"
  default     = false
}

variable "queue_all_runs" {
  type        = bool
  description = "Queue all runs on workspace creation"
  default     = false
}

variable "enable_remote_state_sharing" {
  type        = bool
  description = "Enable automatic remote state sharing between workspaces"
  default     = false
}
