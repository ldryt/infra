resource "desec_rrset" "root_A_record" {
  domain  = local.dns.zone
  subname = ""
  type    = "A"
  records = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl     = 86400
}

resource "desec_rrset" "servers_subdomains" {
  for_each = local.servers

  domain  = local.dns.zone
  subname = each.key
  type    = "A"
  records = [each.value.ip]
  ttl     = 86400
}

resource "desec_rrset" "silvermist_subdomains" {
  for_each = local.dns.subdomains

  domain  = local.dns.zone
  subname = each.value
  type    = "A"
  records = [hcloud_primary_ip.silvermist_ipv4.ip_address]
  ttl     = 86400
}

# https://desec.readthedocs.io/en/latest/dns/rrsets.html#caveats
resource "desec_rrset" "root_MX_record" {
  domain  = local.dns.zone
  subname = ""
  type    = "MX"
  records = ["10 ${local.dns.subdomains.mailserver}.${local.dns.zone}."]
  ttl     = 86400
}

resource "desec_rrset" "root_TXT_record__SPF" {
  domain  = local.dns.zone
  subname = ""
  type    = "TXT"
  records = ["\"v=spf1 a:${local.dns.subdomains.mailserver}.${local.dns.zone} -all\""]
  ttl     = 86400
}

resource "desec_rrset" "root_TXT_record__DMARC" {
  domain  = local.dns.zone
  subname = "_dmarc"
  type    = "TXT"
  records = ["\"v=DMARC1; p=reject;\""]
  ttl     = 86400
}

resource "desec_rrset" "root_TXT_record__DKIM" {
  domain  = local.dns.zone
  subname = "mail._domainkey"
  type    = "TXT"
  records = ["\"v=DKIM1; k=rsa; p=MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAp/lQpx6ykzt33icAxzUS8vck5LBbaSDJB8d00xXvCl253RfPDtnfhVT8u4myWCQm5O3e/YHY8hEjESkFpt+u23Siz8Wqhbko6YCX/KIZo72biii+wc69bfND2qBc+epjPnNi0FLTviyJVQAgDDt5iZWgZU8GiWj6SKRqBlirc8Hh/Ix/K+YUFu3BR8FJ/p5AtSc2UPpJdckU+dGAflYn7HycPwgrbgE5FnaF0zQibIcEpTbrWC8TxOqFLdczOmfLVGhESG05lAz9vinoF+bLc+JgwEeOO5efO0qfQRuG8gQJyf75/CniD6tVLavD4RF8AiovrkAdwpnv0n3osy8pZdsQnDgIuGoTCG4/dSu6hlxgg6zvqIpjNt4e8sKXrvf1Dj5f1X1XUzYXF7FNg7k3BdnDndNCceRD3DUyB9R5g2g0DaCiBbpQkKREZFVpu4RKzdrBk0iqPDUU7FYP+s/2qKMK7oExCPcIyIyfRAp/GrZVi+mUQ4sNAf43jsc2zjjBxOyBIsqV1nIngTE6sH2gOsEjoHOoetqdMFTPPJdbf3hiQ34BNy0xb3a7GGEIUb3Zc11mhH0Xfqdg4FszP1aWmnKMPyRzzL+3c06/uFTMIdT/TfLlu6/xMGppDmqApQ9Vr2RhXmdGBeVlVq+K0vg5Ic31mIu8wp74m/N05s9Eri8CAwEAAQ==\""]
  ttl     = 86400
}

resource "desec_rrset" "root_TXT_record__DNSWL" {
  domain  = local.dns.zone
  subname = "_token._dnswl"
  type    = "TXT"
  records = ["\"d811ej3o0jy5la15dvnxvgwn32ymg2uw\""]
  ttl     = 86400
}

resource "desec_rrset" "root_SRV_record__IMAPS" {
  domain  = local.dns.zone
  subname = "_imaps._tcp"
  type    = "SRV"
  records = ["5 0 993 ${local.dns.subdomains.mailserver}.${local.dns.zone}."]
  ttl     = 86400
}

resource "desec_rrset" "root_SRV_record__IMAP" {
  domain  = local.dns.zone
  subname = "_imap._tcp"
  type    = "SRV"
  records = ["5 0 143 ${local.dns.subdomains.mailserver}.${local.dns.zone}."]
  ttl     = 86400
}

resource "desec_rrset" "root_SRV_record__SUBMISSIONS" {
  domain  = local.dns.zone
  subname = "_submissions._tcp"
  type    = "SRV"
  records = ["5 0 465 ${local.dns.subdomains.mailserver}.${local.dns.zone}."]
  ttl     = 86400
}

resource "desec_rrset" "root_SRV_record__SUBMISSION" {
  domain  = local.dns.zone
  subname = "_submission._tcp"
  type    = "SRV"
  records = ["5 0 587 ${local.dns.subdomains.mailserver}.${local.dns.zone}."]
  ttl     = 86400
}
