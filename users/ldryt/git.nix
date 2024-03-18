{ vars, ... }: {
  programs.git = {
    enable = true;
    userName =
      "${vars.sensitive.users.ldryt.name} ${vars.sensitive.users.ldryt.surname}";
    userEmail = vars.sensitive.users.ldryt.email;
  };
}
