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
    model = cfg.model;
    model_reasoning_effort = cfg.modelReasoningEffort;
    personality = cfg.personality;

    projects = builtins.listToAttrs (
      map (path: {
        name = path;
        value = {
          trust_level = "trusted";
        };
      }) cfg.trustedProjects
    );

    notice = {
      hide_full_access_warning = true;
      hide_rate_limit_model_nudge = true;
      model_migrations = {
        "gpt-5.2" = "gpt-5.2-codex";
        "gpt-5.2-codex" = cfg.model;
      };
    };

    mcp_servers = {
      pencil = {
        command = config.shared.mcp.pencil.mcpPath;
        args = config.shared.mcp.pencil.mcpArgs;
      };
    };
  };
in
{
  options.home-manager.cli.codex = {
    enable = lib.mkEnableOption "Codex CLI config";

    model = lib.mkOption {
      type = lib.types.str;
      default = "gpt-5.4";
      description = "Default model used by Codex.";
    };

    modelReasoningEffort = lib.mkOption {
      type = lib.types.enum [
        "minimal"
        "low"
        "medium"
        "high"
        "xhigh"
      ];
      default = "xhigh";
      description = "Default reasoning effort used by Codex.";
    };

    personality = lib.mkOption {
      type = lib.types.str;
      default = "pragmatic";
      description = "Default personality used by Codex.";
    };

    trustedProjects = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "${config.home.homeDirectory}/nix-configs"
        "${config.home.homeDirectory}/code/emit"
      ];
      description = "Project paths that Codex should treat as trusted.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.codex ];

    sops.secrets.codex-auth-json = {
      path = "${config.home.homeDirectory}/.codex/auth.json";
      mode = "0600";
    };

    home.file.".codex/config.toml".source = tomlFormat.generate "codex-config.toml" codexConfig;
  };
}
