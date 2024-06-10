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
