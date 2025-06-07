terraform {
  cloud {
    organization = "ldryt-infra"
    workspaces {
      name = "silvermist"
    }
  }
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~>1.51.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~>1.2.0"
    }
    cloudflare = {
      version = "~>5.5.0"
      source  = "cloudflare/cloudflare"
    }
  }
}

locals {
  dns = jsondecode(file("${path.module}/../dns.json"))
}


variable "hcloud_token_file" {
  description = "Hetzner Cloud API Token. Can be loaded using environment variable 'TF_VAR_hcloud_token_file'"
  type        = string
}

variable "cloudflare_token_file" {
  description = "Cloudflare API Token. Can be loaded using environment variable 'TF_VAR_cloudflare_token_file'"
  type        = string
}


provider "sops" {}

provider "cloudflare" {
  api_token = file(var.cloudflare_token_file)
}

provider "hcloud" {
  token = file(var.hcloud_token_file)
}
