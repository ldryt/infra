module "deploy" {
  for_each = local.servers

  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  nixos_system_attr      = ".#nixosConfigurations.${each.key}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.key}.config.system.build.diskoScript"

  instance_id = each.value.id
  target_host = each.value.ip
  target_port = each.value.ssh_port

  target_user        = "colon"
  deployment_ssh_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.deploy.colon.sshKey"])

  install_user    = lookup(each.value, "install_user", "root")
  install_ssh_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.install.sshKey"])

  extra_files_script = "${path.module}/deploy-keys.sh"
  disk_encryption_key_scripts = lookup(each.value, "luks", false) ? [{
    path   = "/tmp/disk.key"
    script = "${path.module}/decrypt-luks-key.sh"
  }] : []

  extra_environment = merge(
    {
      "SERVER_NAME"     = each.key
      "SERVER_SOPS_KEY" = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.install.self-sops-key"])
    },
    lookup(each.value, "luks", false) ? {
      "LUKS_PASSPHRASE"   = nonsensitive(data.sops_file.secrets[each.key].data["disko.luks.passphrase"])
      "SECUREBOOT_BUNDLE" = nonsensitive(data.sops_file.secrets[each.key].data["secureboot.bundle"])
    } : {}
  )

  debug_logging   = true
  build_on_remote = true
}
