{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos.server.opencode;
  authSecret = "opencode-auth-json";
  deepseekSecret = "deepseek-api-key";
  envFile = "opencode-env";
  user = "opencode-main";
  group = "opencode";
  stateDir = "/var/lib/opencode/state";
in
{
  options.nixos.server.opencode = {
    enable = lib.mkEnableOption "opencode headless server" // {
      default = false;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4096;
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };

    directory = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/opencode/workdir";
      description = "Working directory opencode operates in (shared via group with syncthing).";
    };

    workdirOwner = lib.mkOption {
      type = lib.types.str;
      default = "znaniye";
      description = "User that owns the workdir (syncthing peer).";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "opencode config.json contents (rendered verbatim).";
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

    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = stateDir;
      createHome = false;
      shell = pkgs.bashInteractive;
    };

    nixos.server.opencode.settings = lib.mkDefault {
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

    systemd.tmpfiles.rules = [
      "d /var/lib/opencode 0755 root root -"
      "d ${stateDir} 0750 ${user} ${group} -"
      "d ${cfg.directory} 2770 ${cfg.workdirOwner} ${group} -"
      "d ${cfg.directory}/.stfolder 2770 ${cfg.workdirOwner} ${group} -"
    ];

    systemd.services.opencode-main = {
      description = "opencode headless server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = with pkgs; [
        git
        coreutils
        bashInteractive
        findutils
        gnugrep
        gnused
        which
      ];
      environment = {
        HOME = stateDir;
      };
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = cfg.directory;
        EnvironmentFile = config.sops.templates.${envFile}.path;
        LoadCredential = [
          "opencode-auth.json:${config.sops.secrets.${authSecret}.path}"
        ];
        ExecStartPre = pkgs.writeShellScript "opencode-main-prestart" ''
          install -d -m 0700 "$HOME/.local/share/opencode"
          install -d -m 0700 "$HOME/.config/opencode"
          install -m 0600 ${pkgs.writers.writeJSON "opencode.json" cfg.settings} \
            "$HOME/.config/opencode/opencode.json"
          if [ -f "$CREDENTIALS_DIRECTORY/opencode-auth.json" ]; then
            install -m 0600 "$CREDENTIALS_DIRECTORY/opencode-auth.json" \
              "$HOME/.local/share/opencode/auth.json"
          fi
        '';
        ExecStart = "${pkgs.opencode}/bin/opencode serve --print-logs --port ${toString cfg.port} --hostname ${cfg.hostname}";
        Restart = "on-failure";
        RestartSec = "5s";
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          stateDir
          cfg.directory
        ];
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    networking.firewall.interfaces = lib.genAttrs cfg.allowedInterfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });
  };
}
