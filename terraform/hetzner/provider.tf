terraform {
  required_providers {
    sops = {
      source = "carlpett/sops"
      version = "~> 0.5"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  backend "s3" {}
}

provider "hcloud" {
    token = data.sops_file.terraform_secrets.data["terraform.hcloud.token"]
}