variable "tfc_organization_name" {
  type        = string
  description = "HCP Terraform Cloud organization name for enterprise deployment"

  validation {
    condition     = length(var.tfc_organization_name) > 0 && length(var.tfc_organization_name) <= 255
    error_message = "Organization name must be between 1 and 255 characters."
  }
}

variable "business_unit" {
  type        = string
  description = "Business unit to process ('finance', 'engineering', 'marketing', or 'all' for multi-BU deployment)"
  default     = "all"

  validation {
    condition     = contains(["finance", "engineering", "marketing", "all"], var.business_unit) || can(regex("^[a-z0-9_-]+$", var.business_unit))
    error_message = "Business unit must be 'all', one of the predefined BUs, or a valid lowercase identifier."
  }
}
