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
  backend "s3" {
    bucket = "backblaze-terraform-states"
    key    = "hetzner/terraform.tfstate"
    region = "eu-central-003"
    endpoints = {
      s3 = "https://s3.eu-central-003.backblazeb2.com"
    }
    # Backblaze B2 is S3-compatible but is not AWS
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    use_path_style              = true
    # credentials: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY = B2 application key
  }
}

provider "hcloud" {
    token = data.sops_file.terraform_secrets.data["terraform.hcloud.token"]
}