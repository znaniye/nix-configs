{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.cli.codex;
  tomlFormat = pkgs.formats.toml { };
  codexConfig = {
    mcp_servers = {
      pencil = {
        args = [ ];
        command = config.shared.mcp.pencil.command;
      };
    };
    model = cfg.model;
    model_reasoning_effort = cfg.modelReasoningEffort;
    notice = {
      hide_full_access_warning = true;
      hide_rate_limit_model_nudge = true;
      model_migrations = {
        "gpt-5.2" = "gpt-5.2-codex";
        "gpt-5.2-codex" = cfg.model;
      };
    };
    personality = cfg.personality;
    projects = builtins.listToAttrs (
      map (path: {
        name = path;
        value = {
          trust_level = "trusted";
        };
      }) cfg.trustedProjects
    );
  };
in
{
  config = lib.mkIf cfg.enable {
    home.file.".codex/config.toml".source = tomlFormat.generate "codex-config.toml" codexConfig;
    home.packages = [ pkgs.codex ];
    sops.secrets.codex-auth-json = {
      mode = "0600";
      path = "${config.home.homeDirectory}/.codex/auth.json";
    };
  };
  options.home-manager.cli.codex = {
    enable = lib.mkEnableOption "Codex CLI config";

    model = lib.mkOption {
      default = "gpt-5.4";
      description = "Default model used by Codex.";
      type = lib.types.str;
    };

    modelReasoningEffort = lib.mkOption {
      default = "xhigh";
      description = "Default reasoning effort used by Codex.";
      type = lib.types.enum [
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
      ];
    };

    personality = lib.mkOption {
      default = "pragmatic";
      description = "Default personality used by Codex.";
      type = lib.types.str;
    };

    trustedProjects = lib.mkOption {
      default = [
        "${config.home.homeDirectory}/nix-configs"
        "${config.home.homeDirectory}/code/emit"
      ];
      description = "Project paths that Codex should treat as trusted.";
      type = with lib.types; listOf str;
    };
  };
}
