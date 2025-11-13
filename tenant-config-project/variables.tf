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
  description = "Business unit identifier used for resource naming and filtering YAML configurations. Should match the 'bu' field in config/*.yaml files."
  default     = "bu1"

  validation {
    condition     = length(var.business_unit) > 0 && can(regex("^[a-z0-9_-]+$", var.business_unit))
    error_message = "Business unit must be a non-empty string containing only lowercase letters, numbers, underscores, and hyphens."
  }
}