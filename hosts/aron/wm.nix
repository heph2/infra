{ config, pkgs, ... }: {
  services.aerospace = {
    package = pkgs.aerospace;
    enable = false;
    settings = {
      enable-normalization-flatten-containers = false;
      enable-normalization-opposite-orientation-for-nested-containers = false;

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      mode.main.binding = {
        "alt-enter" = ''
          exec-and-forget osascript -e '
          tell application "Terminal"
          do script
          activate
          end tell'
        '';

        "alt-j" = "focus --boundaries-action wrap-around-the-workspace left";
        "alt-k" = "focus --boundaries-action wrap-around-the-workspace down";
        "alt-l" = "focus --boundaries-action wrap-around-the-workspace up";
        "alt-semicolon" =
          "focus --boundaries-action wrap-around-the-workspace right";

        "alt-shift-j" = "move left";
        "alt-shift-k" = "move down";
        "alt-shift-l" = "move up";
        "alt-shift-semicolon" = "move right";

        "alt-h" = "split horizontal";
        "alt-v" = "split vertical";

        "alt-f" = "fullscreen";

        "alt-s" = "layout v_accordion";
        "alt-w" = "layout h_accordion";
        "alt-e" = "layout tiles horizontal vertical";

        "alt-shift-space" = "layout floating tiling";

        "alt-1" = "workspace 1";
        "alt-2" = "workspace 2";
        "alt-3" = "workspace 3";
        "alt-4" = "workspace 4";
        "alt-5" = "workspace 5";
        "alt-6" = "workspace 6";
        "alt-7" = "workspace 7";
        "alt-8" = "workspace 8";
        "alt-9" = "workspace 9";
        "alt-0" = "workspace 10";

        "alt-shift-1" = "move-node-to-workspace 1";
        "alt-shift-2" = "move-node-to-workspace 2";
        "alt-shift-3" = "move-node-to-workspace 3";
        "alt-shift-4" = "move-node-to-workspace 4";
        "alt-shift-5" = "move-node-to-workspace 5";
        "alt-shift-6" = "move-node-to-workspace 6";
        "alt-shift-7" = "move-node-to-workspace 7";
        "alt-shift-8" = "move-node-to-workspace 8";
        "alt-shift-9" = "move-node-to-workspace 9";
        "alt-shift-0" = "move-node-to-workspace 10";

        "alt-shift-c" = "reload-config";
        "alt-r" = "mode resize";
      };

      mode.resize.binding = {
        "h" = "resize width -50";
        "j" = "resize height +50";
        "k" = "resize height -50";
        "l" = "resize width +50";
        "enter" = "mode main";
        "esc" = "mode main";
      };
    };
  };

  services.yabai = {
    enable = true;
    config = {
      external_bar = "off:40:0";
      menubar_opacity = 1.0;
      mouse_follows_focus = "on";
      focus_follows_mouse = "on";
      display_arrangement_order = "default";
      window_origin_display = "default";
      window_placement = "second_child";
      window_zoom_persist = true;
      window_shadow = true;
      window_animation_duration = 0.0;
      window_animation_easing = "ease_out_circ";
      window_opacity_duration = 0.0;
      active_window_opacity = 1.0;
      normal_window_opacity = 0.9;
      window_opacity = "off";
      insert_feedback_color = "0xffd75f5f";
      split_ratio = 0.5;
      split_type = "auto";
      auto_balance = false;
      top_padding = 12;
      bottom_padding = 12;
      left_padding = 12;
      right_padding = 12;
      window_gap = 6;
      layout = "bsp";
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };
  };

  services.skhd = {

    enable = true;
    skhdConfig = ''
      # skhdrc example configuration

      # reload skhd
      cmd + alt + ctrl - r : skhd --reload

      # basic window focus controls
      alt - h : yabai -m window --focus west
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - l : yabai -m window --focus east

      # basic window movement controls
      alt + shift - h : yabai -m window --swap west
      alt + shift - j : yabai -m window --swap south
      alt + shift - k : yabai -m window --swap north
      alt + shift - l : yabai -m window --swap east

      # resizing windows
      alt + cmd - h : yabai -m window --resize left:-30:0
      alt + cmd - l : yabai -m window --resize right:30:0
      alt + cmd - k : yabai -m window --resize top:0:-30
      alt + cmd - j : yabai -m window --resize bottom:0:30

      # toggle window fullscreen
      alt - f : yabai -m window --toggle zoom-fullscreen

      # toggle window floating
      cmd + f : yabai -m window --toggle float

      # switch workspaces
      cmd - 1 : yabai -m space --focus 1
      alt - 2 : yabai -m space --focus 2
      alt - 3 : yabai -m space --focus 3
      alt - 4 : yabai -m space --focus 4
      alt - 5 : yabai -m space --focus 5

      # move windows to workspaces
      alt + shift - 1 : yabai -m window --space 1
      alt + shift - 2 : yabai -m window --space 2
      alt + shift - 3 : yabai -m window --space 3
      alt + shift - 4 : yabai -m window --space 4
      alt + shift - 5 : yabai -m window --space 5

      # launch applications
      hyper - e : open /Applications/Ghostty.app
      cmd + shift - b : open /Applications/Firefox.app
      cmd + shift - c : open -a "Visual Studio Code"

      # close window
      cmd + q : yabai -m window --close
    '';
  };

  services.spacebar = {
    enable = false;
    package = pkgs.spacebar;
    config = {
      position = "top";
      display = "main";
      height = 26;
      title = "on";
      spaces = "on";
      clock = "on";
      power = "on";
      padding_left = 20;
      padding_right = 20;
      spacing_left = 25;
      spacing_right = 15;
      text_font = ''"Hack Nerd Font:Regular:12.0"'';
      icon_font = ''"Hack Nerd Font:Regular:12.0"'';
      background_color = "0xff202020";
      foreground_color = "0xffa8a8a8";
      power_icon_color = "0xffcd950c";
      battery_icon_color = "0xffd75f5f";
      dnd_icon_color = "0xffa8a8a8";
      clock_icon_color = "0xffa8a8a8";
      power_icon_strip = " ";
      space_icon = "•";
      space_icon_strip = "1 2 3 4 5 6 7 8 9 10";
      spaces_for_all_displays = "on";
      display_separator = "on";
      display_separator_icon = "";
      space_icon_color = "0xff458588";
      space_icon_color_secondary = "0xff78c4d4";
      space_icon_color_tertiary = "0xfffff9b0";
      clock_icon = "";
      dnd_icon = "";
      clock_format = ''"%d/%m/%y %R"'';
      right_shell = "on";
      right_shell_icon = "";
      right_shell_command = "whoami";
    };
  };

  services.sketchybar = {
    enable = true;
    config = ''
      sketchybar --bar height=24
      sketchybar --update
    '';
  };
}
