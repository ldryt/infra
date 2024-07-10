data "sops_file" "silvermist_secrets" {
  source_file = "${path.module}/../secrets.yaml"
}
