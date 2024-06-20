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

variable "create_zarina" {
  description = "Flag to create or not host zarina"
  type        = bool
  default     = false
}

module "zarina" {
  count  = var.create_zarina ? 1 : 0
  source = "./hosts/zarina"
}

module "silvermist" {
  source = "./hosts/silvermist"
}
