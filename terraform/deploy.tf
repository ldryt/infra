locals {
  _servers          = { for k, v in local.servers : k => v if !lookup(v, "no_install", false) }
  noinstall_servers = { for k, v in local.servers : k => v if lookup(v, "no_install", false) }
}

module "deploy" {
  for_each = local._servers

  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  nixos_system_attr      = ".#nixosConfigurations.${each.key}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.key}.config.system.build.diskoScript"

  instance_id     = each.value.id
  target_host     = each.value.ip
  target_port     = each.value.ssh_port
  build_on_remote = false

  target_user        = "colon"
  deployment_ssh_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.deploy.colon.sshKey"])

  install_user    = "root"
  install_ssh_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.install.sshKey"])

  extra_files_script = "${path.module}/deploy-sops-key.sh"
  extra_environment = {
    "SERVER_NAME"     = each.key
    "SERVER_SOPS_KEY" = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.install.self-sops-key"])
  }

  debug_logging = true
}

module "build" {
  for_each = local.noinstall_servers

  source = "github.com/nix-community/nixos-anywhere//terraform/nix-build"

  attribute = ".#nixosConfigurations.${each.key}.config.system.build.toplevel"
}

module "deploy_noinstall" {
  for_each = local.noinstall_servers

  source = "github.com/nix-community/nixos-anywhere//terraform/nixos-rebuild"

  nixos_system = module.build[each.key].result.out
  target_user  = "colon"
  target_host  = each.value.ip
  target_port  = each.value.ssh_port

  ssh_private_key = nonsensitive(data.sops_file.secrets[each.key].data["nixos-anywhere.deploy.colon.sshKey"])
}
