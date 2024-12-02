## Place your Terraform Args / Provider version args here
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.2.1"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "0.54.0"
    }
  }

  cloud {
    organization = "cloudbrokeraz"

    workspaces {
      name = "strat_arch_workspace_control"
      project = "strat_arch_control"
    }
  }
}


provider "github" {
  # Configuration options
  owner = var.github_org
}

provider "tfe" {
  organization = var.organization
}
