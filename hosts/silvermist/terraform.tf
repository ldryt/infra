terraform {
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
