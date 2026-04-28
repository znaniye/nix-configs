{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.cli.codex;
  tomlFormat = pkgs.formats.toml { };
  pencilExtensionBase = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      name = "pencildev";
      publisher = "highagency";
      version = "0.6.38";
      hash = "sha256-SpmKjxBttOdMCrPCxvXp93ZnS+UAd0vRxAOx0BSKIuc=";
    };
  };
  pencilExtension = pencilExtensionBase.overrideAttrs (oldAttrs: {
    postFixup = (oldAttrs.postFixup or "") + ''
      mcpBinary="$out/share/vscode/extensions/highagency.pencildev/out/mcp-server-linux-x64"
      if [ -f "$mcpBinary" ]; then
        mv "$mcpBinary" "$mcpBinary.real"
        cat > "$mcpBinary" <<EOF
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.stdenv.cc.bintools.dynamicLinker} --library-path ${
        pkgs.lib.makeLibraryPath [ pkgs.glibc ]
      } "$mcpBinary.real" "\$@"
      EOF
        chmod +x "$mcpBinary"
      fi
    '';
  });
  pencilMcpPath = "${pencilExtension}/share/vscode/extensions/highagency.pencildev/out/mcp-server-linux-x64";
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
        command = pencilMcpPath;
        args = [
          "--app"
          "vscodium"
        ];
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
