{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.hardware.networking;
in
{
  imports = [ ../../../shared/system/networking/default.nix ];

  options.khanelinix.hardware.networking = with types; {
    hosts =
      mkOpt attrs { }
        "An attribute set to merge with <option>networking.hosts</option>";
  };

  config = mkIf cfg.enable {
    khanelinix.user.extraGroups = [ "networkmanager" ];

    networking = {
      hosts =
        {
          "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
        }
        // cfg.hosts;

      networkmanager = {
        enable = true;
        dhcp = "internal";
      };
    };

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
