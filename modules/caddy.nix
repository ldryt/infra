{ vars, ... }: {
  services.caddy = {
    enable = true;
    email = vars.sensitive.users.ldryt.email;
  };
}
