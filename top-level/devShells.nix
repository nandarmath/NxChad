{ inputs, ... }:
{
  perSystem = { pkgs, lib, ... }:
  {
    legacyPackages = pkgs;
    devShells.default = pkgs.mkShellNoCC {
      NIXD_PATH = lib.concatStringsSep ":" [
        "pkgs=${inputs.self}#legacyPackages.${pkgs.system}"
        "nixvim=${inputs.self}#packages.${pkgs.system}.default.options"
      ];
    };
  };
}
