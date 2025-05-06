{ internal, lib, helpers ? lib.nixvim, ... }:
{ config, lib, ... }:
{
  plugins.indent-blankline = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings = {
      event = "User FilePost";
      cmd = [ "IBLEnable" "IBLDisable" "IBLEnableScope" "IBLDisableScope" "IBLToggle" "IBLToggleScope" ];

      after.__raw = helpers.mkLuaFn /* lua */ ''
        local hooks = require "ibl.hooks"
        hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
        require('ibl').setup(${helpers.toLuaObject
          config.plugins.indent-blankline.settings
        })
      '';
    };
    settings = {
      indent = { char = "│"; highlight = "IblChar"; };
      scope = { char = "│"; highlight = "IblScopeChar"; };
    };
  };
}
