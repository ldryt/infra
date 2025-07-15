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


variable "hcloud_token" {
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  type      = string
  sensitive = true
}


provider "sops" {}

provider "cloudflare" {
  api_token = var.cloudflare_token
}

provider "hcloud" {
  token = var.hcloud_token
}
