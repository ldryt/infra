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
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.68.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~>1.2.0"
    }
    desec = {
      source  = "valodim/desec"
      version = "~>0.6.1"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~>2.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~>3.0"
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
  servers = merge(
    {
      "silvermist" = {
        id        = hcloud_server.silvermist_server.id
        ip        = hcloud_primary_ip.silvermist_ipv4.ip_address
        ssh_port  = 22
        sops_file = "${path.module}/../hosts/silvermist/secrets.yaml"
      },
      "domus" = {
        id        = "domus-2026-06-25"
        ip        = "82.67.219.252"
        ssh_port  = 34971
        sops_file = "${path.module}/../hosts/domus/secrets.yaml"
        luks      = true
      },
      # "printer" = {
      #   id         = "printer-id-2026-01-14"
      #   ip         = "printer.local"
      #   ssh_port   = 22
      #   sops_file  = "${path.module}/../hosts/printer/secrets.yaml"
      #   no_install = true
      #   dns        = false
      # }
      # "luke" = {
      #   id        = "luke-id-2025-12-12"
      #   ip        = "129.151.231.71"
      #   ssh_port  = 22
      #   sops_file = "${path.module}/../hosts/luke/secrets.yaml"
      # }
    },
    var.vidia ? {
        "vidia" = {
        id           = one(openstack_compute_instance_v2.vidia[*].id)
        ip           = one(openstack_compute_instance_v2.vidia[*].access_ip_v4)
        ssh_port     = 22
        sops_file    = "${path.module}/../hosts/vidia/secrets.yaml"
        install_user = "debian"
        dns          = false
      }
    } : {}
  )
}


variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "desec_token" {
  type      = string
  sensitive = true
}

variable "scw_access_key" {
  type      = string
  sensitive = true
}
variable "scw_secret_key" {
  type      = string
  sensitive = true
}
variable "scw_project_id" {
  type      = string
  sensitive = true
}

variable "vidia" {
  type    = bool
  default = false
}

provider "sops" {}

provider "desec" {
  api_token = var.desec_token
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "scaleway" {
  access_key = var.scw_access_key
  secret_key = var.scw_secret_key
  project_id = var.scw_project_id
  region     = "fr-par"
  zone       = "fr-par-2"
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3/" # Authentication URL
  domain_name = "default" # Domain name - Always at 'default' for OVHcloud
}
