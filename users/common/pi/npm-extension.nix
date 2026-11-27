{ name, src }:
{ lib, pkgs, ... }:
let
  package = lib.importJSON (src + "/package.json");
  runtime = pkgs.buildNpmPackage {
    pname = package.name;
    version = package.dependencies.${name};
    inherit src;
    npmDeps = pkgs.importNpmLock { npmRoot = src; };
    inherit (pkgs.importNpmLock) npmConfigHook;
    dontNpmBuild = true;
  };
in
{
  home.file.".pi/agent/extensions/${name}".source =
    "${runtime}/lib/node_modules/${package.name}/node_modules/${name}";
}
