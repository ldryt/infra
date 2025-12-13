variable "state_passphrase" {
  sensitive = true
}

terraform {
   encryption {
     key_provider "pbkdf2" "state_encryption_passphrase" {
       passphrase = var.state_passphrase
     }
     method "aes_gcm" "state_encryption_method" {
       keys = key_provider.pbkdf2.state_encryption_passphrase
     }
     state {
       method = method.aes_gcm.state_encryption_method
       enforced = true
     }
     plan {
       method = method.aes_gcm.state_encryption_method
       enforced = true
     }
   }
  backend "local" {
    path = "tfstate.json.enc"
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
      source  = "valodim/desec"
      version = "~>0.6.1"
    }
  }
}


locals {
  dns = jsondecode(file("${path.module}/../dns.json"))
  dns_list = flatten([
    for zone, servers in local.dns : [
      for name, services in servers : [
        for service, subname in services : {
          fqdn    = "${subname}.${zone}"
          zone    = zone
          service = service
          subname = subname
          ip      = local.servers[name].ip
        }
      ]
    ]
  ])
  dns_records = { for r in local.dns_list : r.fqdn => r }
  mailserver_record = one([
    for r in local.dns_list : r
    if r.service == "mailserver"
  ])
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
    },
    "luke" = {
      id        = "luke-id-2025-12-12"
      ip        = "129.151.231.71"
      ssh_port  = 22
      sops_file = "${path.module}/../hosts/luke/secrets.yaml"
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
