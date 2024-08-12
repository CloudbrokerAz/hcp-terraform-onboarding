terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.56"
    }

  }
}