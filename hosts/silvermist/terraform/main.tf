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
      version = "~>1.47.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~>1.0.0"
    }
    gandi = {
      version = "~>2.3.0"
      source  = "go-gandi/gandi"
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

variable "gandi_token_file" {
  description = "Gandi Personal Access Token. Can be loaded using environment variable 'TF_VAR_gandi_token_file'"
  type        = string
}


provider "sops" {}

provider "gandi" {
  personal_access_token = file(var.gandi_token_file)
}

provider "hcloud" {
  token = file(var.hcloud_token_file)
}
