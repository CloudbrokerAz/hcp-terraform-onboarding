variable "organization" {
  type        = string
  description = "HCP Terraform organization name"

  validation {
    condition     = length(var.organization) > 0
    error_message = "Organization name must not be empty."
  }
}

variable "github_org" {
  type        = string
  description = "GitHub organization name for Finance BU repositories"

  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization name must not be empty."
  }
}

variable "github_org_owner" {
  type        = string
  description = "GitHub organization owner"

  validation {
    condition     = length(var.github_org_owner) > 0
    error_message = "GitHub organization owner must not be empty."
  }
}

variable "oauth_token_id" {
  type        = string
  description = "OAuth token ID for VCS connection (format: ot-xxxxxxxxx)"
  sensitive   = true

  validation {
    condition     = can(regex("^ot-[a-zA-Z0-9]+$", var.oauth_token_id))
    error_message = "OAuth token ID must start with 'ot-' followed by alphanumeric characters."
  }
}

variable "bu_projects" {
  type        = string
  description = "Finance BU project IDs in JSON format from platform team (get from: terraform output -raw finance_projects_json)"

  validation {
    condition     = can(jsondecode(var.bu_projects))
    error_message = "The bu_projects variable must be a valid JSON string."
  }
}
