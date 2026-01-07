resource "desec_rrset" "root_web_aliases" {
  for_each = {
    for r in local.dns_list : r.zone => r.ip
    if r.subname == "www"
  }

  domain  = each.key
  subname = ""
  type    = "A"
  records = [each.value]
  ttl     = 86400
}

resource "desec_rrset" "servers_subdomains" {
  for_each = local.servers

  domain  = "ldryt.dev"
  subname = each.key
  type    = "A"
  records = [each.value.ip]
  ttl     = 86400
}

resource "desec_rrset" "services_subdomains" {
  for_each = local.dns_records

  domain  = each.value.zone
  subname = each.value.subname
  type    = "A"
  records = [each.value.ip]
  ttl     = 86400
}

###############
# Mail Config
# https://desec.readthedocs.io/en/latest/dns/rrsets.html#caveats

locals {
  mail_config = {
    "ldryt.dev" = {
      dkim  = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAp/lQpx6ykzt33icAxzUS8vck5LBbaSDJB8d00xXvCl253RfPDtnfhVT8u4myWCQm5O3e/YHY8hEjESkFpt+u23Siz8Wqhbko6YCX/KIZo72biii+wc69bfND2qBc+epjPnNi0FLTviyJVQAgDDt5iZWgZU8GiWj6SKRqBlirc8Hh/Ix/K+YUFu3BR8FJ/p5AtSc2UPpJdckU+dGAflYn7HycPwgrbgE5FnaF0zQibIcEpTbrWC8TxOqFLdczOmfLVGhESG05lAz9vinoF+bLc+JgwEeOO5efO0qfQRuG8gQJyf75/CniD6tVLavD4RF8AiovrkAdwpnv0n3osy8pZdsQnDgIuGoTCG4/dSu6hlxgg6zvqIpjNt4e8sKXrvf1Dj5f1X1XUzYXF7FNg7k3BdnDndNCceRD3DUyB9R5g2g0DaCiBbpQkKREZFVpu4RKzdrBk0iqPDUU7FYP+s/2qKMK7oExCPcIyIyfRAp/GrZVi+mUQ4sNAf43jsc2zjjBxOyBIsqV1nIngTE6sH2gOsEjoHOoetqdMFTPPJdbf3hiQ34BNy0xb3a7GGEIUb3Zc11mhH0Xfqdg4FszP1aWmnKMPyRzzL+3c06/uFTMIdT/TfLlu6/xMGppDmqApQ9Vr2RhXmdGBeVlVq+K0vg5Ic31mIu8wp74m/N05s9Eri8CAwEAAQ=="
      dnswl = "d811ej3o0jy5la15dvnxvgwn32ymg2uw"
    }
    "lucasladreyt.eu" = {
      dkim = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAmJVRlsT5kFhSQxbrUVF9djgwwBKi7YyHPLbVrJ1s0MCam4Iha6vsXUwop7XUDSRuXdn8589AKNTBaZzLWPO1+EpNxMHxAe9HNFPhmlbMrkE98AqfvYI2fNZq50gzZOpteHG9O8Grz68LVUAdKA0eLnDfJMjpm3yYoC/+oGS/wJR2dVljPQYdPRjqDuiWGIAK2Pj4vedROnLKkNsrzX+d2AL/Ed86dMJ2AGX343dcWOX9zJqIBD/H6oE91m13mkJne5wR4eYswqZvrHLNhyqYzjRsp58X4HmdZ3F+iob1/LGzf2vxrOECq7a84pmHdHmWyZfE+z5eqb8EFK7iharytXYhCUyjNsJ2hWK4kkiOUeVTYGgaxBTo3CqeZtPc5ZSmLxPTmFahOgvX2AthzAFaySNqWGMWZGa9FEybVMsY4iHXpx82wC/M4CyU+zXZG8o5Y011WTW6/4NeCE0dHLZni6hhiwvnYJeUBJLS+qytbUv4VLFtSht2tY6NiqLbOW1jFDrRGNwPdD7/SwXU267jdI5jE1kp0CKagK+7WsoD3hBc4bPl3/cCl+TtC6mqge0pggG+pBGUQmaFe7UmduFQdurRbyQJf8a69okMrxaOHJgIkLdvivXQBw8gmz4eD84YVENFltIX+KiVtFwDVMg5k5uiHDsjFPXIYKqiYbTXOuMCAwEAAQ=="
    }
  }
  srv_params = {
    "_imaps._tcp"       = "993"
    "_imap._tcp"        = "143"
    "_submissions._tcp" = "465"
    "_submission._tcp"  = "587"
  }
  srv_records_flat = flatten([
    for domain, _ in local.mail_config : [
      for subname, port in local.srv_params : {
        key     = "${domain}:${subname}"
        domain  = domain
        subname = subname
        port    = port
      }
    ]
  ])
}

resource "desec_rrset" "mx_record" {
  for_each = local.mail_config

  domain  = each.key
  subname = ""
  type    = "MX"
  records = ["10 ${local.mailserver_record.fqdn}."]
  ttl     = 86400
}

resource "desec_rrset" "spf_record" {
  for_each = local.mail_config

  domain  = each.key
  subname = ""
  type    = "TXT"
  records = ["\"v=spf1 a:${local.mailserver_record.fqdn} -all\""]
  ttl     = 86400
}

resource "desec_rrset" "dmarc_record" {
  for_each = local.mail_config

  domain  = each.key
  subname = "_dmarc"
  type    = "TXT"
  records = ["\"v=DMARC1; p=reject;\""]
  ttl     = 86400
}

resource "desec_rrset" "dkim_record" {
  for_each = local.mail_config

  domain  = each.key
  subname = "mail._domainkey"
  type    = "TXT"
  records = ["\"v=DKIM1; k=rsa; p=${each.value.dkim}\""]
  ttl     = 86400
}

resource "desec_rrset" "srv_records" {
  for_each = {
    for record in local.srv_records_flat : record.key => record
  }

  domain  = each.value.domain
  subname = each.value.subname
  type    = "SRV"
  records = ["5 0 ${each.value.port} ${local.mailserver_record.fqdn}."]
  ttl     = 86400
}

resource "desec_rrset" "dnswl_record" {
  for_each = {
    for domain, data in local.mail_config : domain => data
    if lookup(data, "dnswl", null) != null
  }

  domain  = each.key
  subname = "_token._dnswl"
  type    = "TXT"
  records = ["\"${each.value.dnswl}\""]
  ttl     = 86400
}
