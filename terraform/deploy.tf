module "deploy" {
  for_each = local.servers

  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  nixos_system_attr      = ".#nixosConfigurations.${each.key}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.key}.config.system.build.diskoScript"

  instance_id = each.value.id
  target_host = each.value.ip

  target_user        = "colon"
  deployment_ssh_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.deploy.colon.sshKey"])

  install_user    = "root"
  install_ssh_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.install.sshKey"])

  extra_files_script = "${path.module}/deploy-sops-key.sh"
  extra_environment = {
    "SERVER_NAME" = each.key
  }
}
