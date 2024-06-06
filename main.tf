terraform {
  cloud {
    organization = "ldryt-infra"
    workspaces {
      name = "main"
    }
  }
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

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "sops" {}

data "sops_file" "silvermist_secrets" {
  source_file = "hosts/silvermist/secrets.yaml"
}

variable "gandi_token" {
  sensitive = true
}

provider "gandi" {
  personal_access_token = var.gandi_token
}

resource "hcloud_firewall" "silvermist_firewall" {
  labels = {
    "silvermist" : true
  }
  name = "silvermist_firewall"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
}

resource "hcloud_primary_ip" "silvermist_ipv4" {
  labels = {
    "silvermist" : true
  }
  name          = "silvermist_ipv4"
  datacenter    = "fsn1-dc14"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
}

resource "hcloud_ssh_key" "silvermist_ssh_key" {
  labels = {
    "silvermist" : true
  }
  name       = "silvermist_ssh_key"
  public_key = data.sops_file.silvermist_secrets.data["users.colon.sshPubKey"]
}

resource "hcloud_server" "silvermist_server" {
  labels = {
    "silvermist" = true
  }
  name         = "silvermist"
  image        = "debian-12"
  server_type  = "cx22"
  datacenter   = "fsn1-dc14"
  firewall_ids = [hcloud_firewall.silvermist_firewall.id]
  ssh_keys     = [hcloud_ssh_key.silvermist_ssh_key.id]
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.silvermist_ipv4.id
    ipv6_enabled = false
  }
}

module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere?ref=1.2.0//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${hcloud_server.silvermist_server.name}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${hcloud_server.silvermist_server.name}.config.system.build.diskoScript"

  instance_id        = hcloud_server.silvermist_server.id
  target_host        = hcloud_primary_ip.silvermist_ipv4.ip_address
  target_user        = "colon"
  install_user       = "root"
  install_ssh_key    = nonsensitive(data.sops_file.silvermist_secrets.data["users.colon.sshKey"])
  deployment_ssh_key = nonsensitive(data.sops_file.silvermist_secrets.data["users.colon.sshKey"])

  extra_files_script = "${path.module}/terraform-deploy-keys.sh"
  extra_environment = {
    "SERVER_NAME" = hcloud_server.silvermist_server.name
  }

  # debug_logging          = true
}

variable "subdomains" {
  description = "List of subdomains"
  type        = list(string)
  default     = ["auth", "files", "mc", "pass", "pics"]
}

resource "gandi_livedns_record" "silvermist_A_record" {
  name   = "silvermist"
  zone   = "ldryt.dev"
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "silvermist_subdomains" {
  for_each = toset(var.subdomains)

  name   = each.key
  zone   = "ldryt.dev"
  type   = "CNAME"
  values = ["silvermist"]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_A_record" {
  name   = "@"
  zone   = "ldryt.dev"
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}
