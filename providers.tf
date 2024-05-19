terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~>1.47.0"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}
