{ ... }: {
  sops.defaultSopsFile = ../../secrets/tinkerbell.yaml;
  sops.age.keyFile = "/var/lib/sops/sops_tinkerbell_age_key";

  sops.secrets."users/ldryt/hashedPassword".neededForUsers = true;
}
