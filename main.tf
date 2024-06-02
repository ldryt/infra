resource "hcloud_firewall" "kiwi_firewall" {
  labels = {
    "kiwi" : true
  }
  name = "kiwi_firewall"
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

resource "hcloud_primary_ip" "kiwi_ipv4" {
  labels = {
    "kiwi" : true
  }
  name          = "kiwi_ipv4"
  datacenter    = "fsn1-dc14"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
}

resource "hcloud_ssh_key" "kiwi_ssh_key" {
  labels = {
    "kiwi" : true
  }
  name       = "kiwi_ssh_key"
  public_key = file("~/.keyring/ssh_kiwi_colon.pub")
}

resource "hcloud_server" "kiwi_server" {
  labels = {
    "kiwi" = true
  }
  name         = "kiwi"
  image        = "debian-12"
  server_type  = "cax11"
  datacenter   = "fsn1-dc14"
  firewall_ids = [hcloud_firewall.kiwi_firewall.id]
  ssh_keys     = [hcloud_ssh_key.kiwi_ssh_key.id]
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.kiwi_ipv4.id
    ipv6_enabled = false
  }
}

module "deploy" {
  source                 = "github.com/nix-community/nixos-anywhere?ref=1.2.0//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${hcloud_server.kiwi_server.name}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${hcloud_server.kiwi_server.name}.config.system.build.diskoScript"

  instance_id        = hcloud_server.kiwi_server.id
  target_host        = hcloud_primary_ip.kiwi_ipv4.ip_address
  target_user        = "colon"
  install_user       = "root"
  deployment_ssh_key = "/home/ldryt/.keyring/ssh_kiwi_colon.key"

  extra_files_script = "${path.module}/terraform-deploy-keys.sh"
  extra_environment = {
    "SERVER_NAME"  = hcloud_server.kiwi_server.name
    "KEYRING_PATH" = "/home/ldryt/.keyring"
  }

  # debug_logging          = true
}
