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

module "zarina" {
  source = "./hosts/zarina"
}

module "silvermist" {
  source = "./hosts/silvermist"
}
