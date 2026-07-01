{ pkgs, lib, ... }:

let

  ROOT = /etc/nixos;
  MODULES = "${ROOT}/modules";
  nix_config = import ("${ROOT}/config.nix") { inherit pkgs; };

  enable = service:
    lib.setAttrByPath
      ((lib.splitString "." service) ++ [ "enable" ]) true;

  modules =
    builtins.filter builtins.pathExists
      (map (module: "${MODULES}/services/${module}.nix") nix_config.environment.services);

in

{
 imports = []
  ++ modules;

  services = lib.mkMerge (map enable nix_config.environment.services);
}