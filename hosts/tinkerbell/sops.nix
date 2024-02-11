{ ... }: {
  sops.defaultSopsFile = ../../secrets/tinkerbell.yaml;
  sops.age.keyFile = "/etc/ssh/ssh_host_ed25519_key";


  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
}
