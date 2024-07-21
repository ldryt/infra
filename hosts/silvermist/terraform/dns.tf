resource "cloudflare_record" "silvermist_A_record" {
  name    = "silvermist"
  zone_id = local.dns.zone
  type    = "A"
  value   = hcloud_primary_ip.silvermist_ipv4.ip_address
  proxied = false
}

resource "cloudflare_record" "root_A_record" {
  name    = "@"
  zone_id = local.dns.zone
  type    = "A"
  value   = hcloud_primary_ip.silvermist_ipv4.ip_address
  proxied = false
}

resource "cloudflare_record" "silvermist_subdomains" {
  for_each = local.dns.subdomains

  name    = each.value
  zone_id = local.dns.zone
  type    = "CNAME"
  value   = "silvermist"
  proxied = false
}

resource "cloudflare_record" "root_MX_record" {
  name    = "@"
  zone_id = local.dns.zone
  type    = "MX"
  value   = local.dns.zone
}

resource "cloudflare_record" "root_TXT_record__SPF" {
  name    = "@"
  zone_id = local.dns.zone
  type    = "TXT"
  value   = "v=spf1 mx ~all"
}

resource "cloudflare_record" "root_TXT_record__DKIM" {
  name    = "@"
  zone_id = local.dns.zone
  type    = "TXT"
  value   = nonsensitive(data.sops_file.silvermist_secrets.data["services.opendkim.selectors.main.txt"])
}
