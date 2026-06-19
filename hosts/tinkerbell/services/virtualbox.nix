{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  ldryt-infra.persist.users.ldryt.directories = [
    "VirtualBox VMs"
    ".config/VirtualBox"
  ];
}
