resource "gandi_livedns_record" "silvermist_A_record" {
  name   = "silvermist"
  zone   = local.dns.zone
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_A_record" {
  name   = "@"
  zone   = local.dns.zone
  type   = "A"
  values = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl    = 86400
}

resource "gandi_livedns_record" "silvermist_subdomains" {
  for_each = local.dns.subdomains

  name   = each.value
  zone   = local.dns.zone
  type   = "CNAME"
  values = ["silvermist"]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_MX_record" {
  name   = "@"
  zone   = local.dns.zone
  type   = "MX"
  values = [local.dns.zone]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_TXT_record__SPF" {
  name   = "@"
  zone   = local.dns.zone
  type   = "TXT"
  values = ["v=spf1 mx ~all"]
  ttl    = 86400
}

resource "gandi_livedns_record" "root_TXT_record__DKIM" {
  name   = "@"
  zone   = local.dns.zone
  type   = "TXT"
  values = [nonsensitive(data.sops_file.silvermist_secrets.data["services.opendkim.selectors.main.txt"])]
  ttl    = 86400
}
