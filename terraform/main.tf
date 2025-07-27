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
    desec = {
      source  = "Valodim/desec"
      version = "~>0.6.1"
    }
  }
}

locals {
  dns = jsondecode(file("${path.module}/../dns.json"))
}


variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "desec_token" {
  type      = string
  sensitive = true
}


provider "sops" {}

provider "desec" {
  api_token = var.desec_token
}

provider "hcloud" {
  token = var.hcloud_token
}
