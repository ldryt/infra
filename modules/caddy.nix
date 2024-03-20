{ vars, ... }: {
  services.caddy = {
    enable = true;
    email = vars.sensitive.services.caddy.email;
  };
}
