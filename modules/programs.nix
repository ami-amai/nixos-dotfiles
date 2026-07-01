{ pkgs, lib, ... }:

let

  ROOT = /etc/nixos;
  MODULES = "${ROOT}/modules";
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

  enable = program:
    lib.setAttrByPath
      ((lib.splitString "." program) ++ [ "enable" ]) true;

  modules =
    builtins.filter builtins.pathExists
      (map (module: "${MODULES}/programs/${module}.nix") nix_config.environment.programs);

in

{
  imports = []
  ++ modules;

  programs = lib.mkMerge (map enable nix_config.environment.programs);
}