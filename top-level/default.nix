{ inputs, self, config, lib, ... } @ v:
{
  systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
  imports = lib.fmway.genImports ./. ++ [
    ({ lib, ... }: {
      flake = lib.fmway.genModules ../modules v;
    })
  ];
  flake = { inherit lib; };
}
