terraform {
  cloud {
    organization = "ldryt-infra"
    workspaces {
      name = "zarina"
    }
  }
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

variable "ignore_instance_zarina" {
  description = "Flag to determine whether to ignore the instance named 'zarina'. This instance is costly and its deployment is automated."
  type        = bool
  default     = true
}

provider "google" {
  project = "tidy-arena-428113-b3"
}

provider "google-beta" {
  project = "tidy-arena-428113-b3"
}
