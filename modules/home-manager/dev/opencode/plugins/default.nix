{
  lib,
  notificationSound,
  pkgs,
}:
let
  mkPlugin =
    {
      name,
      source,
      substitutions ? { },
    }:
    let
      keys = builtins.attrNames substitutions;
      values = map (key: substitutions.${key}) keys;
    in
    pkgs.writeTextFile {
      name = "opencode-plugin-${name}.js";
      text = lib.replaceStrings keys values (builtins.readFile source);
    };

  configuredPlugins = {
    notification = {
      enabled = true;
      source = ./notification.js;
      substitutions = {
        __NOTIFICATION_SOUND__ = notificationSound;
        __PAPLAY_COMMAND__ = "${pkgs.pulseaudio}/bin/paplay";
      };
    };
  };

  enabledPlugins = lib.filterAttrs (_: plugin: plugin.enabled or true) configuredPlugins;
  packagedPlugins = lib.mapAttrs (
    name: plugin:
    mkPlugin {
      inherit name;
      inherit (plugin) source;
      substitutions = plugin.substitutions or { };
    }
  ) enabledPlugins;
in
{
  entries = lib.mapAttrsToList (_: pluginPath: "file://${pluginPath}") packagedPlugins;
}
