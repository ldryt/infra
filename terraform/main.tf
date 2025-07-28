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
  servers = {
    "silvermist" = {
      id        = hcloud_server.silvermist_server.id
      ip        = hcloud_primary_ip.silvermist_ipv4.ip_address
      ssh_port  = 22
      sops_file = "${path.module}/../hosts/silvermist/secrets.yaml"
    },
    "tp420ia" = {
      id        = "tp420ia-id-2025-07-12"
      ip        = "82.65.203.15"
      ssh_port  = 34971
      sops_file = "${path.module}/../hosts/tp420ia/secrets.yaml"
    }
  }
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
