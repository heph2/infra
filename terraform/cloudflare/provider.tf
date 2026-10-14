terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "backblaze-terraform-states"
    key    = "cloudflare/terraform.tfstate"
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

provider "cloudflare" {
  # token from CLOUDFLARE_API_TOKEN (agenix, loaded by terraform/.envrc)
}
