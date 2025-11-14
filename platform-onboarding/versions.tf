terraform {
  required_version = ">= 1.13.5"
  
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60"
    }
    
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# NO provider blocks - Stacks will configure providers
