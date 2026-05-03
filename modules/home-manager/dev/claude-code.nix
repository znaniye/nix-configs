{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.dev.claude-code;
  notificationSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";

  giteaMcpWrapper = pkgs.writeShellScriptBin "gitea-mcp-wrapper" ''
    #!/bin/bash
    TOKEN=$(cat ${config.sops.secrets.gitea-pat-token.path})
    exec ${pkgs.gitea-mcp-server}/bin/gitea-mcp \
      -host "${cfg.giteaMcp.host}" \
      -token "$TOKEN" \
      "$@"
  '';

  claudeCodeWithEnv = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [ pkgs.claude-code ];
    postBuild = ''
      rm -f "$out/bin/claude"
      cat > "$out/bin/claude" <<EOF
      #!${pkgs.bash}/bin/bash
      export PATH="${pkgs.nodejs}/bin:\$PATH"
      export ANTHROPIC_BASE_URL="${cfg.anthropicBaseUrl}"
      export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.chromium}/bin/chromium"
      if [ -f "${config.sops.secrets.anthropic-auth-token.path}" ]; then
        export ANTHROPIC_AUTH_TOKEN="\$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.anthropic-auth-token.path})"
      fi
      exec ${pkgs.claude-code}/bin/claude "\$@"
      EOF
      chmod +x "$out/bin/claude"
    '';
  };
in
{
  options.home-manager.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code config" // {
      default = config.home-manager.dev.enable;
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "opus";
      description = "Default Claude Code model.";
    };

    anthropicBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://192.168.150.11:4444";
      description = "Base URL for the Anthropic API.";
    };

    giteaMcp = {
      enable = lib.mkEnableOption "Gitea MCP server integration" // {
        default = true;
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "http://192.168.68.111:3000";
        description = "Gitea host URL used by the MCP server.";
      };
    };

    rtk = {
      enable = lib.mkEnableOption "RTK token-saving Bash proxy" // {
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        jq
        agent-browser
        chromium
      ])
      ++ lib.optional cfg.rtk.enable pkgs.rtk;

    nixpkgs = {
      config.allowUnfreePredicate =
        pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "claude-code"
          "claude"
        ];
    };

    sops.secrets = {
      anthropic-auth-token.path = "${config.xdg.configHome}/secrets/anthropic-auth-token";
    }
    // lib.optionalAttrs cfg.giteaMcp.enable {
      gitea-pat-token = { };
    };

    programs.claude-code = {
      enable = true;
      package = claudeCodeWithEnv;
      mcpServers = lib.optionalAttrs cfg.giteaMcp.enable {
        gitea-mcp = {
          type = "stdio";
          command = "${giteaMcpWrapper}/bin/gitea-mcp-wrapper";
        };
      };
      settings = {
        model = cfg.model;
        skipDangerousModePermissionPrompt = true;
        alwaysThinkingEnabled = true;
        permissions = {
          allow = [
            "Bash(cat:*)"
            "Bash(cd:*)"
            "Bash(echo:*)"
            "Bash(git add:*)"
            "Bash(git branch:*)"
            "Bash(git commit:*)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "Bash(git remote -v:*)"
            "Bash(git rev-parse:*)"
            "Bash(git show:*)"
            "Bash(git stash list:*)"
            "Bash(git status:*)"
            "Bash(ls:*)"
            "Bash(find:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(wc:*)"
            "Bash(pwd:*)"
            "Bash(which:*)"
            "Bash(tree:*)"
            "Bash(mkdir:*)"
            "Bash(npm run:*)"
            "Bash(npm test:*)"
            "Bash(npm install:*)"
            "Bash(npm ci:*)"
            "Bash(npx:*)"
            "Bash(node:*)"
            "Bash(go build:*)"
            "Bash(go test:*)"
            "Bash(go vet:*)"
            "Bash(go fmt:*)"
            "Bash(go mod tidy:*)"
            "Bash(make:*)"
            "Bash(terraform fmt:*)"
            "Bash(terraform validate:*)"
            "Bash(terraform plan:*)"
            "Bash(tofu fmt:*)"
            "Bash(tofu validate:*)"
            "Bash(tofu plan:*)"
            "Bash(gh pr:*)"
            "Bash(gh issue:*)"
            "Bash(gh repo view:*)"
            "Bash(jq:*)"
            "Bash(grep:*)"
            "Bash(rg:*)"
            "Bash(sort:*)"
            "Bash(uniq:*)"
            "Bash(diff:*)"
            "Bash(nix build:*)"
            "Bash(nix flake check:*)"
            "Bash(nix flake show:*)"
            "Bash(nix flake metadata:*)"
            "Bash(nix fmt:*)"
            "Bash(nix eval:*)"
            "Bash(nix develop:*)"
            "Bash(nix log:*)"
            "Bash(nix path-info:*)"
            "Bash(nix search:*)"
            "Bash(nixfmt:*)"
            "Bash(agent-browser:*)"
            "Read"
            "Edit"
            "Write"
            "Glob"
            "Grep"
            "Agent"
            "WebFetch(domain:github.com)"
            "WebFetch(domain:mynixos.com)"
            "WebSearch"
          ];
          deny = [
            "Bash(rm -rf:*)"
            "Bash(git push --force:*)"
            "Bash(git reset --hard:*)"
            "Bash(git clean -f:*)"
            "Bash(terraform apply:*)"
            "Bash(tofu apply:*)"
            "Bash(terraform destroy:*)"
            "Bash(tofu destroy:*)"
            "Bash(sbt publish:*)"
          ];
        };
        attribution = {
          commit = "";
          pr = "";
        };
        hooks = {
          PreToolUse = lib.mkIf cfg.rtk.enable [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.rtk}/bin/rtk hook claude";
                }
              ];
            }
          ];
          Notification = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
                }
                {
                  type = "command";
                  command = "${pkgs.libnotify}/bin/notify-send 'Claude Code' 'Session needs your attention' 2>/dev/null || true";
                }
              ];
            }
          ];
          Stop = [
            {
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.pulseaudio}/bin/paplay ${notificationSound} 2>/dev/null || true";
                }
                {
                  type = "command";
                  command = "${pkgs.libnotify}/bin/notify-send 'Claude Code' 'Task finished' 2>/dev/null || true";
                }
              ];
            }
          ];
        };

        # Plugin marketplace configuration
        extraKnownMarketplaces = {
          ossystems = {
            source = {
              source = "github";
              repo = "OSSystems/claude-code-plugin";
            };
          };
          caveman = {
            source = {
              source = "github";
              repo = "JuliusBrussee/caveman";
            };
          };
        };

        enabledPlugins = {
          "ossystems-commit@ossystems" = true;
          "caveman@caveman" = true;
        };
      };
    };
  };
}
