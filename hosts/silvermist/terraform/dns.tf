locals {
  zone_id = "39509d1b1fb62e1c6623562d537b0bcb"
}

resource "cloudflare_record" "silvermist_A_record" {
  zone_id = local.zone_id
  name    = "silvermist"
  value   = hcloud_primary_ip.silvermist_ipv4.ip_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "root_A_record" {
  zone_id = local.zone_id
  name    = "@"
  value   = hcloud_primary_ip.silvermist_ipv4.ip_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "silvermist_subdomains" {
  for_each = local.dns.subdomains

  zone_id = local.zone_id
  name    = each.value
  value   = "silvermist"
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "root_MX_record" {
  zone_id = local.zone_id
  name    = "@"
  value   = local.dns.zone
  type    = "MX"
  priority = 10
}

resource "cloudflare_record" "root_TXT_record__SPF" {
  zone_id = local.zone_id
  name    = "@"
  value   = "v=spf1 mx ~all"
  type    = "TXT"
}

resource "cloudflare_record" "root_TXT_record__DKIM" {
  zone_id = local.zone_id
  name    = "@"
  value   = nonsensitive(data.sops_file.silvermist_secrets.data["services.opendkim.selectors.main.txt"])
  type    = "TXT"
}
