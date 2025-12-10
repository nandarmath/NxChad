{ internal, lib, helpers ? lib.nixvim, ... }:
{
  plugins.which-key = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings = {
      cmd = "WhichKey";
      keys = [
        "<leader>" "<c-r>" "<c-w>" "\"" "'" "`" "c" "v" "g"
      ];
    };
  };
}
