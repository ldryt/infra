data "sops_file" "silvermist_secrets" {
  source_file = "./hosts/silvermist/secrets.yaml"
}
