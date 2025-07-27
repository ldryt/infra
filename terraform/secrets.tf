data "sops_file" "silvermist_secrets" {
  source_file = "${path.module}/../hosts/silvermist/secrets.yaml"
}
