{ internal, lib, inputs, helpers ? lib.nixvim, ... }:
let
  inherit (helpers) mkLuaFn toLuaObject nKeymap';
in
{ pkgs, config, lib,... }:
let
  cfg = config.nvchad;
  chadrc = cfg.config // {
    base46 = removeAttrs cfg.config.base46 [ "second_theme" ];
  };
  base46-cache = inputs.self.packages.${pkgs.system}.base46-cache.override {
    inherit chadrc;
  };
in
{
  _file = ./default.nix;
  imports = [
    ./option.nix
    (lib.mkAliasOptionModule [ "nvchad" ] [ "nxchad" ])
  ];
  config = lib.mkIf cfg.enable {
    plugins.lz-n.enable = true;
    extraPlugins = with pkgs.vimPlugins; [
      plenary-nvim
      inputs.self.packages.${pkgs.system}.base46-patch
      nvchad-ui
      (pkgs.vimUtils.buildVimPlugin {
        name = "chadrc";
        src = pkgs.writeTextFile {
          name = "chadrc.lua";
          text = /* lua */ ''
            local M = ${toLuaObject chadrc}
            return M
          '';
          destination = "/lua/chadrc.lua";
        };
      })
    ];
    extraConfigLuaPre = lib.mkBefore /* lua */ ''
      -- disable some plugins
      vim.g.loaded_netrwPlugin = 1
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwSettings = 1
      vim.g.loaded_netrwFileHandlers = 1
      vim.g.loaded_netrw_gitignore = 1
      vim.g.loaded_zip = 1
      vim.g.loaded_zipPlugin = 1
      vim.g.loaded_2html_plugin = 1
      vim.g.loaded_gzip = 1
      vim.g.loaded_tarPlugin = 1

      vim.g.base46_cache = "${base46-cache}/"

      pcall(function()
        dofile(vim.g.base46_cache .. "syntax")
        dofile(vim.g.base46_cache .. "treesitter")
        dofile(vim.g.base46_cache .. "nvimtree")
        dofile(vim.g.base46_cache .. "devicons")
      end)
      -- for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
      --   dofile(vim.g.base46_cache .. v)
      -- end
    '';
    extraConfigLua = /* lua */ ''
      -- go to previous/next line with h,l,left arrow and right arrow
      -- when cursor reaches end/beginning of line
      vim.opt.whichwrap:append "<>[]hl"
    '';

    extraConfigLuaPost = /* lua */ ''
      vim.opt.shortmess:append "sI"

      require "nvchad"
      
      require("nvim-web-devicons").setup {
        override = require "nvchad.icons.devicons",
      }
    '';
    plugins.telescope = {
      lazyLoad.settings.before.__raw = mkLuaFn /* lua */ ''
        dofile(vim.g.base46_cache .. "telescope")
      '';
      enabledExtensions = [
        "themes"
        "terms"
      ];
    };

    plugins.gitsigns.lazyLoad.settings.before.__raw =
      mkLuaFn /* lua */ ''
        dofile(vim.g.base46_cache .. "git")
      '';

    plugins.indent-blankline.lazyLoad.settings.before.__raw =
      mkLuaFn /* lua */ ''
        dofile(vim.g.base46_cache .. "blankline")
      '';

    plugins.which-key.lazyLoad.settings.before.__raw = 
      mkLuaFn /* lua */ ''
        dofile(vim.g.base46_cache .. "whichkey")
      '';

    plugins.web-devicons.enable = true;

    plugins.lsp.lazyLoad.settings.before.__raw = mkLuaFn /* lua */ ''
      dofile(vim.g.base46_cache .. "lsp")
      require('lz.n').trigger_load('blink.cmp')
      require("nvchad.lsp").diagnostic_config()
    '';
    plugins.lsp.keymaps.extra = [
      (nKeymap' "<leader>ra" {
        __raw = /* lua */ ''require "nvchad.lsp.renamer"'';
      } "NVRenamer")
    ];

    plugins.blink-cmp.lazyLoad.settings = {
      before.__raw = mkLuaFn /* lua */ ''
        local lz = require('lz.n')
        lz.trigger_load('nvim-autopairs')
        lz.trigger_load('luasnip')
        lz.trigger_load('blink.compat')
      '';
      after.__raw = mkLuaFn /* lua */ ''
        local default = ${toLuaObject config.plugins.blink-cmp.settings}
        local opts = vim.tbl_deep_extend("force", default, require "nvchad.blink.config")
        require("blink-cmp").setup(opts)
      '';
    };
    keymaps = [
      (nKeymap' "<leader>ch" "<cmd>NvCheatsheet<CR>" "toggle nvcheatsheet")

      # tabufline
      (nKeymap' "<leader>b" ("<cmd>en" + "ew<CR>") "buffer new")
      (nKeymap' "<tab>" {
        __raw = mkLuaFn /* lua */ ''require("nvchad.tabufline").next()'';
      } "buffer goto next")
      (nKeymap' "<S-tab>" {
        __raw = mkLuaFn /* lua */ ''
          require("nvchad.tabufline").prev()'';
      } "buffer goto prev")
      (nKeymap' "<leader>x" {
        __raw = mkLuaFn /* lua */ ''
          require("nvchad.tabufline").close_buffer()'';
      } "buffer close")

      (nKeymap' "<leader>th" {
        __raw = mkLuaFn /* lua */ ''
          require("nvchad.themes").open()'';
      } "telescope nvchad themes")
       # new terminals
      (nKeymap' "<leader>h" {
        __raw = mkLuaFn /* lua */ ''
          require("nvchad.term").new { pos = "sp" }'';
      } "terminal new horizontal term")
      (nKeymap' "<leader>v" {
        __raw = mkLuaFn /* lua */ ''
          require("nvchad.term").new { pos = "vsp" }'';
      } "terminal new vertical term")

      # toggleable
      {
        mode = ["n" "t"];
        key = "<A-v>";
        action.__raw = mkLuaFn /* lua */ ''
          require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }'';
        options.desc = "terminal toggleable vertical term";
      }
      {
        mode = ["n" "t"];
        key = "<A-h>";
        action.__raw = mkLuaFn /* lua */ ''
          require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }'';
        options.desc = "terminal toggleable horizontal term";
      }
      {
        mode = ["n" "t"];
        key = "<A-i>";
        action.__raw = mkLuaFn /* lua */ ''
          require("nvchad.term").toggle { pos = "float", id = "floatTerm" }'';
        options.desc = "terminal toggle floating term";
      }
    ];
    colorscheme = "nvchad";
  };
}
