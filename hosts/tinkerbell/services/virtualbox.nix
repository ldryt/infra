{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  environment.persistence.tinkerbell.users.ldryt.directories = [
    "VirtualBox VMs"
    ".config/VirtualBox"
  ];
}
