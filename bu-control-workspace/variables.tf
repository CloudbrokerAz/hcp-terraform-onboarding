# Organization level variables
variable "organization" {
  description = "TFC Organization to build under"
  type        = string
  default     = "cloudbrokeraz"

  validation {
    condition     = length(var.organization) > 0
    error_message = "Organization name must not be empty."
  }
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "hashi-demo-lab"

  validation {
    condition     = length(var.github_org) > 0
    error_message = "GitHub organization name must not be empty."
  }
}

variable "github_org_owner" {
  description = "GitHub organization owner - typically same as github_org"
  type        = string
  default     = "hashi-demo-lab"

  validation {
    condition     = length(var.github_org_owner) > 0
    error_message = "GitHub organization owner must not be empty."
  }
}

variable "oauth_token_id" {
  description = "OAuth token ID for VCS connection (format: ot-xxxxxxxxx)"
  type        = string
  default     = "ot-JKCe2joSPQz55gbq"
  sensitive   = true

  validation {
    condition     = can(regex("^ot-[a-zA-Z0-9]+$", var.oauth_token_id))
    error_message = "OAuth token ID must start with 'ot-' followed by alphanumeric characters."
  }
}

variable "bu_projects" {
  description = "Project JSON lookup - populated by platform tenant configuration. Maps project names to TFC project IDs."
  type        = string
  default     = null

  validation {
    condition     = var.bu_projects == null || can(jsondecode(var.bu_projects))
    error_message = "The bu_projects variable must be a valid JSON string or null."
  }
}