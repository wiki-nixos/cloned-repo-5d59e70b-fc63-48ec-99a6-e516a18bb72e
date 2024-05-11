{ lib, pkgs, ... }:
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      webapi-vim
      nvim-web-devicons
    ];

    plugins = {
      nvim-autopairs.enable = true;

      nix-develop.enable = true;
    };
  };
}
