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
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKpnQLHFPVhJB4jhCjWF1TNaogH/MnpU1JBwzU9JWjRl nixos-anywhere-install@hcloud-silvermist"
}

resource "hcloud_server" "silvermist_server" {
  labels = {
    "silvermist" = true
  }
  name        = "silvermist"
  image       = "debian-12"
  server_type = "cx22"
  datacenter  = "fsn1-dc14"
  ssh_keys    = [hcloud_ssh_key.silvermist_ssh_key.id]
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.silvermist_ipv4.id
    ipv6_enabled = false
  }
}

resource "hcloud_rdns" "silvermist_rdns" {
  server_id  = hcloud_server.silvermist_server.id
  ip_address = hcloud_primary_ip.silvermist_ipv4.ip_address
  dns_ptr    = "${local.dns.subdomains.mailserver}.${local.dns.zone}"
}
