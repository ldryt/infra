variable "subdomains" {
  description = "List of subdomains"
  type        = list(string)
  default     = ["auth", "files", "pass", "pics"]
}

resource "gandi_livedns_record" "silvermist_A_record" {
  name   = "silvermist"
  zone   = "ldryt.dev"
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_A_record" {
  name   = "@"
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
