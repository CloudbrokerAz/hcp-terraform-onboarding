provider "aws" {
  region = var.region
}

provider "tfe" {
  hostname = var.tfc_hostname
}

terraform {
  cloud {
    hostname     = "tfe.simon-lynch.sbx.hashidemos.io"
    organization = "myorg"

    workspaces {
      name    = "tfc-tenant-config"
      project = "platform_team"
    }
  }

}