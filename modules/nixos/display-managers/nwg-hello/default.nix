{ config
, inputs
, lib
, options
, pkgs
, system
, ...
}:
let
  inherit (lib) types mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt mkOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.display-managers.nwg-hello;
  greetdHyprlandConfig = pkgs.writeText "greetd-hyprland-config" ''
    ${cfg.hyprlandOutput}

    bind=SUPER, RETURN, exec, ${getExe pkgs.wezterm}
    bind=SUPER_SHIFT, RETURN, exec, ${getExe pkgs.nwg-hello}

    exec-once = ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE

    exec-once = ${getExe pkgs.nwg-hello} -d -l
    exec-once =  ${getExe' config.programs.hyprland.package "hyprctl"} exit
  '';
  greetdSwayConfig = pkgs.writeText "greetd-sway-config" ''
    exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK
    exec systemctl --user import-environment

    ${cfg.swayOutput}

    input "type:touchpad" {
      tap enabled
    }

    seat seat0 xcursor_theme ${config.khanelinix.desktop.addons.gtk.cursor.name} 24

    xwayland disable

    bindsym XF86MonBrightnessUp exec light -A 5
    bindsym XF86MonBrightnessDown exec light -U 5
    bindsym Print exec ${getExe pkgs.grim} /tmp/regreet.png
    bindsym Mod4+shift+e exec ${getExe' config.programs.sway.package "swaynag"} \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'

    exec "${getExe pkgs.nwg-hello} -d -l; ${getExe' config.programs.sway.package "swaymsg"} exit"
  '';
in
{
  options.khanelinix.display-managers.nwg-hello = with types; {
    enable = mkBoolOpt false "Whether or not to enable greetd.";
    hyprlandOutput = mkOpt lines "" "Hyprlands Outputs config.";
    swayOutput = mkOpt lines "" "Sways Outputs config.";
  };

  config =
    mkIf cfg.enable
      {
        environment.systemPackages = [
          config.khanelinix.desktop.addons.gtk.cursor.pkg
          config.khanelinix.desktop.addons.gtk.icon.pkg
          config.khanelinix.desktop.addons.gtk.theme.pkg
        ];

        programs.nwg-hello = {
          enable = true;
          package = pkgs.nwg-hello;

          settings =
            {
              background = {
                path = pkgs.khanelinix.wallpapers.flatppuccin_macchiato;
                fit = "Cover";
              };

              session_dirs = [
                "${config.programs.hyprland.package}/share/wayland-sessions"
              ];

              custom_sessions = [
                {
                  name = "Hyprland";
                  exec = "${getExe config.programs.hyprland.package}";
                }
              ];

              monitor_nums = [ ];
              delay_secs = 1;

              prefer-dark-theme = true;
              gtk-cursor-theme = "${config.khanelinix.desktop.addons.gtk.cursor.name}";
              gtk-font-name = "${config.khanelinix.system.fonts.default} * 12";
              gtk-icon-theme = "${config.khanelinix.desktop.addons.gtk.icon.name}";
              gtk-theme = "${config.khanelinix.desktop.addons.gtk.theme.name}";
            };
        };

        services.greetd = {
          settings = {
            default_session = {
              # command = "${getExe config.programs.hyprland.package} --config ${greetdHyprlandConfig} > /tmp/hyprland-log-out.txt 2>&1";
              command = "env GTK_USE_PORTAL=0 ${getExe nixpkgs-wayland.packages.${system}.sway-unwrapped} --config ${greetdSwayConfig}";
            };
          };

          restart = false;
        };

        security.pam.services.greetd = {
          enableGnomeKeyring = true;
          gnupg.enable = true;
        };
      };
}
