{
  imports = [
    (import ../npm-extension.nix {
      name = "pi-hashline-edit";
      src = ./.;
    })
  ];

  home.file.".pi/agent/hashline.json".text = builtins.toJSON {
    grep = true;
  };
}
