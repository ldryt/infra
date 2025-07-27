data "sops_file" "secrets" {
  for_each = local.servers

  source_file = each.value.sops_file
}
