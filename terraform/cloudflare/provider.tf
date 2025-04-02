terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    sops = {
      source = "carlpett/sops"
      version = "~> 0.5"
    }
  }
  backend "s3" {}
}

provider "cloudflare" {
  api_token = data.sops_file.terraform_secrets.data["terraform.cloudflare.api_token"]
}
