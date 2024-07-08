variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "gandi_token" {
  sensitive = true
}

provider "gandi" {
  personal_access_token = var.gandi_token
}

provider "sops" {}

provider "google" {
  project = "tidy-arena-428113-b3"
}

provider "google-beta" {
  project = "tidy-arena-428113-b3"
}

variable "zarina" {
  description = "Flag to create or not host zarina"
  type        = bool
  default     = false
}

module "zarina" {
  source = "./hosts/zarina"

  create_zarina_instance = var.zarina
}

module "silvermist" {
  source = "./hosts/silvermist"
}
