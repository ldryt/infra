terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~>1.0.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~>5.36.0"
    }
  }
}
