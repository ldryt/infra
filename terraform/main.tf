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
      method   = method.aes_gcm.state_encryption_method
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state_encryption_method
      enforced = true
    }
  }
  backend "local" {
    path = "tfstate.json.enc"
  }
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.4.0"
    }
    desec = {
      source  = "valodim/desec"
      version = "~> 0.6.1"
    }
  }
}

locals {
  dns = jsondecode(file("${path.module}/../dns.json"))
  dns_list = flatten([
    for zone, services in local.dns : [
      for service, v in services : {
        service = service
        subname = v[0]
        fqdn    = "${v[0]}.${zone}"
        zone    = zone
        ips     = [for host in slice(v, 1, length(v)) : local.servers[host].ip]
      }
    ]
  ])
  dns_records = { for r in local.dns_list : r.fqdn => r }
  mailserver_record = one([
    for r in local.dns_list : r
    if r.service == "mailserver"
  ])
  servers = {
    domus = {
      id        = "domus-2026-06-25"
      ip        = jsondecode(file("${path.module}/../ips.json")).domus
      ssh_port  = 34971
      sops_file = "${path.module}/../hosts/domus/secrets.yaml"
      luks      = true
    }
  }
}

variable "desec_token" {
  type      = string
  sensitive = true
}

provider "sops" {}

provider "desec" {
  api_token = var.desec_token
}
