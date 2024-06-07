data "sops_file" "zarina_secrets" {
  source_file = "./hosts/zarina/secrets.yaml"
}
