{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.dev.pi-agent;
  jsonFormat = pkgs.formats.json { };

  secretPath = config.sops.secrets.deepseek-api-key.path;

  pluginPath = lib.makeBinPath [
    pkgs.nodejs
    pkgs.git
    pkgs.gcc
    pkgs.gnumake
    pkgs.python3
  ];

  piAgentWithEnv = pkgs.symlinkJoin {
    name = "pi-coding-agent";
    paths = [ pkgs.pi-coding-agent ];
    postBuild = ''
      rm -f "$out/bin/pi"
      cat > "$out/bin/pi" <<EOF
      #!${pkgs.bash}/bin/bash
      export PATH="${pluginPath}:\$PATH"
      unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL \
            OPENAI_API_KEY OPENAI_BASE_URL CODEX_API_KEY
      if [ -f "${secretPath}" ]; then
        export DEEPSEEK_API_KEY="\$(${pkgs.coreutils}/bin/cat ${secretPath})"
      fi
      exec ${pkgs.pi-coding-agent}/bin/pi "\$@"
      EOF
      chmod +x "$out/bin/pi"
    '';
  };

  models = {
    providers.deepseek = {
      baseUrl = cfg.baseUrl;
      api = "openai-completions";
      apiKey = "$DEEPSEEK_API_KEY";
      models = [
        {
          id = "deepseek-v4-flash";
          name = "DeepSeek V4 Flash";
          reasoning = true;
          input = [ "text" ];
          contextWindow = 350000;
          maxTokens = 384000;
        }
      ];
    };
  };

  settings = lib.recursiveUpdate {
    defaultProvider = "deepseek";
    defaultModel = cfg.defaultModel;
    defaultThinkingLevel = cfg.defaultThinkingLevel;
    theme = cfg.theme;
    quietStartup = cfg.quietStartup;
    enableInstallTelemetry = false;
    packages = cfg.packages;
  } cfg.extraSettings;

  giteaSkill = pkgs.writeTextDir "skills/gitea/SKILL.md" ''
    ---
    name: gitea
    description: Interact with the self-hosted Gitea instance (${config.shared.mcp.gitea.host}). Use for repository management, issues, pull requests, actions, and code reviews.
    ---

    # Gitea Operations

    This skill uses the Gitea MCP server to interact with the local Gitea instance.

    ## Available Commands

    The Gitea MCP binary is available as `gitea-mcp-wrapper` in PATH. Use it with:

    ```bash
    gitea-mcp-wrapper --help
    ```

    ## Common Operations

    The MCP server provides tools for:
    - Repository management (create, list, search)
    - Issue and pull request management
    - Reviewing code and managing merge requests
    - Gitea Actions (workflows, runs)
    - User and organization management
    - File management in repositories
  '';
in
{
  options.home-manager.dev.pi-agent = {
    enable = lib.mkEnableOption "Pi coding agent config" // {
      default = config.home-manager.dev.enable;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = piAgentWithEnv;
      defaultText = lib.literalExpression "wrapped pkgs.pi-coding-agent";
      description = "Pi coding agent package to install.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://api.deepseek.com";
      description = "Base URL of the DeepSeek API.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "deepseek-v4-flash";
      description = "Default model used by pi-agent.";
    };

    defaultThinkingLevel = lib.mkOption {
      type = lib.types.enum [
        "off"
        "low"
        "medium"
        "high"
      ];
      default = "high";
      description = "Default thinking level (only used by reasoning-capable models).";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "dark";
      description = "UI theme.";
    };

    quietStartup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Suppress startup banner output.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf jsonFormat.type;
      default = [
        "git:github.com/lucasmeijer/pi-bash-live-view"
      ];
      description = ''
        Pi packages installed on first run. Entries are either source strings
        (`npm:`, `git:`, absolute path) or filter objects per pi packages.md.
        `npm:` global installs fail on NixOS; prefer `git:` sources, which
        pi clones to ~/.pi/agent/git/ at startup.
      '';
    };

    giteaMcp = {
      enable = lib.mkEnableOption "Gitea MCP server integration" // {
        default = true;
      };
    };

    extraSettings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = "Extra settings merged into ~/.pi/agent/settings.json.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ]
      ++ lib.optional cfg.giteaMcp.enable config.shared.mcp.gitea.wrapper;

    sops.secrets.deepseek-api-key.path = "${config.xdg.configHome}/secrets/deepseek-api-key";

    home.file.".pi/agent/settings.json".source =
      jsonFormat.generate "pi-agent-settings.json" settings;

    home.file.".pi/agent/models.json".source =
      jsonFormat.generate "pi-agent-models.json" models;

    home.file.".pi/agent/extensions/answer.ts".source =
      ./extensions/answer.ts;

    home.file.".pi/agent/skills/gitea/SKILL.md" = lib.mkIf cfg.giteaMcp.enable {
      source = "${giteaSkill}/skills/gitea/SKILL.md";
    };
  };
}
