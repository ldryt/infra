data "sops_file" "zarina_secrets" {
  source_file = "${path.module}/../secrets.yaml"
}
