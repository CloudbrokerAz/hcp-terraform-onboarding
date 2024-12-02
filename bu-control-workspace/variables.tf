# Organization level variables
variable "organization" {
  description = "TFC Organization to build under"
  type        = string
  default     = "cloudbrokeraz"
}

variable "github_org" {
  description = "GitHub organization name"
  default     = "hashi-demo-lab"
}

variable "github_org_owner" {
  description = "GitHub organization name"
  default     = "hashi-demo-lab"
}

variable "oauth_token_id" {
  description = "OAuth token ID"
  type        = string
  default     = "ot-JKCe2joSPQz55gbq"
}

variable "bu_projects" {
  description = "project json lookup - this populated by platform tenant config"
  type        = string
  default     = null
}