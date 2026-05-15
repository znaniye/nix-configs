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
  giteaKnownHosts = pkgs.writeText "opencode-known_hosts" ''
    [192.168.68.111]:2222 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQiiqH2vsocbL6Hp9JHRQckGWNqMl5aW5PbM2oGvp9+R08eW2sb6GkBATGWsBl1Il2lp1mX3Uo4wDCgVpZn6dgKmjrRPFrVCYxmDeI/Kcjt/ugbsC6MsR8N26xlJ1hC1FgkN2taihFbCWOd4wRbhl0omanf2nD1N9if631DmWQvthJmJM0uCWxzuXVEjUKletnzLeOkkwcAeUHAFSJEtVKgZobRA93GuTuFZu/5aHLAEtbR2bx/vVtBTvR6YxSjHNi+TL+Eju5WyVTFA8nS4frHzCJLRGXpDbeoU3GXYu/xMIftJehqvY/rzMzzoyF05j6fCV4Ns9OkZQzDUjqvHtSouYUVxfD8POsEbnGR5ouE44rS0Uig5++4+3qLJiwcirB1zRs6jVma37NGkTf8W2IbNT3dP9CQtCN9DDQkX1s5fJ+fWFFkv2LjvBdvmqqhwSQUbF7XG2pSApt/mhYoQ8TmInvcvkH0Kt7wbJCY56urWdT7e5d9Z28cDQJmKcw7Kjq/B1KnpT8fIqDwIaR+pRxkcJ2OCu83gR1jfEkh+V+xmAinayUQYLgo1UR0W8A5LY3VQz0KbqBbKryaHyJa+cTVYYU4/KgB09fRk2O/wgLDA/iRsCzVRsZOqTgtUXjwPNMm+O7ib43GBGGwTVAUPfoVWTZswKK4F8+MsGUxmOcIQ==
  '';
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
      opencode-main-ssh-key = {
        owner = user;
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

    programs.git.config.user = lib.mkDefault {
      name = "opencode-bot";
      email = "opencode@${config.networking.hostName}.local";
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
        LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
      };
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        WorkingDirectory = cfg.directory;
        EnvironmentFile = config.sops.templates.${envFile}.path;
        LoadCredential = [
          "opencode-auth.json:${config.sops.secrets.${authSecret}.path}"
          "ssh-key:${config.sops.secrets.opencode-main-ssh-key.path}"
        ];
        ExecStartPre = pkgs.writeShellScript "opencode-main-prestart" ''
          install -d -m 0700 "$HOME/.local/share/opencode"
          install -d -m 0700 "$HOME/.config/opencode"
          install -d -m 0700 "$HOME/.ssh"
          install -m 0600 ${pkgs.writers.writeJSON "opencode.json" cfg.settings} \
            "$HOME/.config/opencode/opencode.json"
          if [ -f "$CREDENTIALS_DIRECTORY/opencode-auth.json" ]; then
            install -m 0600 "$CREDENTIALS_DIRECTORY/opencode-auth.json" \
              "$HOME/.local/share/opencode/auth.json"
          fi
          if [ -f "$CREDENTIALS_DIRECTORY/ssh-key" ]; then
            install -m 0600 /dev/null "$HOME/.ssh/id_ed25519"
            cat "$CREDENTIALS_DIRECTORY/ssh-key" > "$HOME/.ssh/id_ed25519"
            tail -c1 "$HOME/.ssh/id_ed25519" | read -r _ || echo >> "$HOME/.ssh/id_ed25519"
          fi
          install -m 0644 ${giteaKnownHosts} "$HOME/.ssh/known_hosts"
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
