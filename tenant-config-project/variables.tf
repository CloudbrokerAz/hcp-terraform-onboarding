variable "cred_type" {
  type        = string
  description = "(optional) describe your variable"
  default     = "project"
}

variable "tfc_organization_name" {
  type        = string
  description = "hcp terraform cloud organization name"
}

variable "business_unit" {
  type    = string
  default = "bu1"
}

variable "tfc_hostname" {
  type        = string
  description = "hcp terraform cloud hostname"
  default     = "tfe.simon-lynch.sbx.hashidemos.io"
}

variable "tfc_aws_audience" {
  type        = string
  description = "hcp terraform cloud aws audience"
  default     = "aws.workload.identity"
}

variable "tfc_project_name" {
  type        = string
  description = "tfc project name"
  default     = "dataproject"
}

variable "tfc_project_id" {
  type        = string
  description = "tf cloud project id"
  default     = ""
}

variable "oidc_provider_arn" {
  type        = string
  description = "oidc provider arn"
  default     = null
}

variable "oidc_provider_client_id_list" {
  type        = list(string)
  description = "oidc provider client id list"
  default     = ["aws.workload.identity"]
}

variable "region" {
  type        = string
  description = "aws region"
  default     = "ap-southeast-2"
}