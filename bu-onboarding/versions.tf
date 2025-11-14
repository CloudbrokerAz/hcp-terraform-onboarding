terraform {
  required_version = ">= 1.13.5"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60"
    }
  }
}

# NOTE: No provider blocks - Stacks will configure providers
# This module is designed to be used with Terraform Stacks where
# providers are configured in the Stack's providers.tfcomponent.hcl file
