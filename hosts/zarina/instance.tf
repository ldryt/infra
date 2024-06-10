resource "hcloud_firewall" "zarina_firewall" {
  labels = {
    "zarina" : true
  }
  name = "zarina_firewall"
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
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "25565"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "24454"
    source_ips = [
      "0.0.0.0/0"
    ]
  }
}

resource "hcloud_primary_ip" "zarina_ipv4" {
  labels = {
    "zarina" : true
  }
  name          = "zarina_ipv4"
  datacenter    = "fsn1-dc14"
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
}

resource "hcloud_ssh_key" "zarina_ssh_key" {
  labels = {
    "zarina" : true
  }
  name       = "zarina_ssh_key"
  public_key = data.sops_file.zarina_secrets.data["users.colon.sshPubKey"]
}

resource "hcloud_server" "zarina_server" {
  labels = {
    "zarina" = true
  }
  name         = "zarina"
  image        = "debian-12"
  server_type  = "cx32"
  datacenter   = "fsn1-dc14"
  firewall_ids = [hcloud_firewall.zarina_firewall.id]
  ssh_keys     = [hcloud_ssh_key.zarina_ssh_key.id]
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.zarina_ipv4.id
    ipv6_enabled = false
  }
}
