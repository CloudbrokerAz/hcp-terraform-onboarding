variable "tfc_organization_name" {
  type        = string
  description = "HCP Terraform Cloud organization name where platform infrastructure will be created"

  validation {
    condition     = length(var.tfc_organization_name) > 0 && length(var.tfc_organization_name) <= 255
    error_message = "Organization name must be between 1 and 255 characters."
  }
}

variable "business_unit" {
  type        = string
  description = "Business unit identifier (must match 'bu' field in config YAML files)"
  default     = "finance"

  validation {
    condition     = length(var.business_unit) > 0 && can(regex("^[a-z0-9_-]+$", var.business_unit))
    error_message = "Business unit must be a non-empty string containing only lowercase letters, numbers, underscores, and hyphens."
  }
}
