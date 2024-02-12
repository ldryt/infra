{ ... }: {
  sops.defaultSopsFile = ../../secrets/tinkerbell.yaml;
  sops.age.keyFile = "/var/lib/sops/age/main.key";

  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
}
