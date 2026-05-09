{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.opencode;
  authSecret = "opencode-auth-json";
  deepseekSecret = "deepseek-api-key";
  envFile = "opencode-env";
  directory = "/var/lib/opencode/workdir";
in
{
  imports = [ flake.inputs.opencode-nix.nixosModules.default ];

  options.nixos.server.opencode = {
    enable = lib.mkEnableOption "opencode headless server" // {
      default = false;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4096;
    };

    allowedInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "tailscale0"
        "end0"
      ];
      description = "Network interfaces allowed to reach opencode (tailnet + LAN).";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      ${authSecret} = {
        owner = "root";
        mode = "0400";
        sopsFile = ../../../secrets/opencode-auth.json;
      };
      ${deepseekSecret} = {
        owner = "root";
        mode = "0400";
      };
    };

    sops.templates.${envFile} = {
      owner = "root";
      mode = "0400";
      content = ''
        DEEPSEEK_API_KEY=${config.sops.placeholder.${deepseekSecret}}
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/opencode 0755 root root -"
      "d ${directory} 0750 opencode-main opencode -"
    ];

    services.opencode = {
      enable = true;
      instances.main = {
        inherit directory;
        listen = {
          address = "0.0.0.0";
          port = cfg.port;
        };
        logLevel = "info";
        path = with pkgs; [
          git
          coreutils
        ];
        environmentFile = config.sops.templates.${envFile}.path;
        config = {
          model = "deepseek/deepseek-v4-flash";
          provider.deepseek = {
            npm = "@ai-sdk/openai-compatible";
            name = "DeepSeek";
            options = {
              baseURL = "https://api.deepseek.com/v1";
              apiKey = "{env:DEEPSEEK_API_KEY}";
            };
            models.deepseek-v4-flash.name = "DeepSeek V4 Flash";
          };
        };
      };
    };

    systemd.services.opencode-main = {
      serviceConfig.LoadCredential = [
        "opencode-auth.json:${config.sops.secrets.${authSecret}.path}"
      ];
      serviceConfig.ExecStartPre = lib.mkAfter [
        (pkgs.writeShellScript "opencode-main-install-auth" ''
          install -d -m 0700 "$HOME/.local/share/opencode"
          if [ -f "$CREDENTIALS_DIRECTORY/opencode-auth.json" ]; then
            install -m 0600 "$CREDENTIALS_DIRECTORY/opencode-auth.json" \
              "$HOME/.local/share/opencode/auth.json"
          fi
        '')
      ];
    };

    networking.firewall.interfaces = lib.genAttrs cfg.allowedInterfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });
  };
}
