{
  description = "A very basic flake";

  inputs = {
    nixpkgs.follows = "fmway-nix/nixpkgs";
    fmway-nix.url = "github:fmway/fmway.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs = { fmway-nix, ... } @ inputs: let
    nixvimLib = let
      generator = { name ? "", args ? [], lua ? "", ... }:
      ''
        function${if name == "" then "" else " ${name}"}(${builtins.concatStringsSep ", " args})
          ${lua}
        end
      '';
    in {
      mkLuaFnWithName = name: x: if builtins.isList x then
        lua: generator { inherit name lua; args = x; }
      else generator { inherit name; args = []; lua = x; };

      mkLuaFn = x: if builtins.isList x then
        lua: generator { inherit lua; args = x; }
      else generator { args = []; lua = x; };
    };
    fnKeymaps = lib: {
      toKeymaps = key: action: { ... } @ options:
        lib.pipe [ key action ] [
          lib.nixvim.listToUnkeyedAttrs
          (x: x // options)
          lib.nixvim.toLuaObject
          (__raw: { inherit __raw; })
        ];
      toKeymaps' =
        key: action: { mode ? "n", ... } @ options: {
          inherit key action mode;
          options = removeAttrs options [ "mode" ];
        };
    };
  in fmway-nix.fmway.mkFlake {
    inherit inputs;
    specialArgs.lib = self: super: let
      splices = arr:
      if arr == [] then []
      else
        self.foldl' (acc: curr: let
          exclude = self.filter (x: curr != x) arr;
        in acc ++ [
          curr
        ] ++ map (x: curr + x) (splices exclude)) [] arr;
    in {
      nixvim = inputs.nixvim.lib.nixvim.extend (_: nixvim: let
        res = fnKeymaps self;
      in nixvimLib // res // self.listToAttrs (map (x: {
        name = "${x}Keymap'";
        value = a: b: desc:
          res.toKeymaps' a b {
            mode = self.stringToCharacters x;
            inherit desc;
          };
      }) (splices [ "n" "v" "i" "t" ])));
    };
  } ./top-level;
}
