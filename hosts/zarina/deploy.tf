module "zarina-deploy" {
  source                 = "github.com/nix-community/nixos-anywhere?ref=1.2.0//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${hcloud_server.zarina_server.name}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${hcloud_server.zarina_server.name}.config.system.build.diskoScript"

  instance_id        = hcloud_server.zarina_server.id
  target_host        = hcloud_primary_ip.zarina_ipv4.ip_address
  target_user        = "colon"
  install_user       = "root"
  install_ssh_key    = nonsensitive(data.sops_file.zarina_secrets.data["users.colon.sshKey"])
  deployment_ssh_key = nonsensitive(data.sops_file.zarina_secrets.data["users.colon.sshKey"])

  extra_files_script = "${path.root}/terraform-deploy-keys.sh"
  extra_environment = {
    "SERVER_NAME" = hcloud_server.zarina_server.name
  }
}
