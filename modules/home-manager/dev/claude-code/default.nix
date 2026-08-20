{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.dev.claude-code;

  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  intervalsMcpWrapper = pkgs.writeShellScriptBin "intervals-mcp-wrapper" ''
    if [ -f "${config.sops.secrets.intervals-api-key.path}" ]; then
      export INTERVALS_ICU_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.intervals-api-key.path})"
    fi
    export INTERVALS_ICU_ATHLETE_ID="${cfg.intervalsMcp.athleteId}"
    exec ${pkgs.uv}/bin/uvx intervals-icu-mcp "$@"
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
      ${lib.optionalString (
        cfg.agentBrowserExecutable != ""
      ) ''export AGENT_BROWSER_EXECUTABLE_PATH="${cfg.agentBrowserExecutable}"''}
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
  config = lib.mkIf cfg.enable {
    home.activation.claudeCodeOnboarding = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_JSON="$HOME/.claude.json"
      if [ ! -f "$CLAUDE_JSON" ]; then
        echo '{}' > "$CLAUDE_JSON"
      fi
      run ${pkgs.jq}/bin/jq '. + {
        hasCompletedOnboarding: true,
        bypassPermissionsModeAccepted: true
      }' "$CLAUDE_JSON" > "$CLAUDE_JSON.tmp"
      run mv "$CLAUDE_JSON.tmp" "$CLAUDE_JSON"
    '';
    home.packages =
      (with pkgs; [
        jq
        agent-browser
      ])
      ++ lib.optional isLinux pkgs.chromium
      ++ lib.optional cfg.rtk.enable pkgs.rtk;
    nixpkgs = {
      config.allowUnfreePredicate =
        pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "claude-code"
          "claude"
        ];
    };
    programs.claude-code = {
      agents = lib.mapAttrs (
        name: agent: config.shared.codingAgents.renderClaudeAgent name agent
      ) config.shared.codingAgents.agents;
      enable = true;
      mcpServers = {
      }
      // lib.optionalAttrs isLinux {
        pencil = {
          command = config.shared.mcp.pencil.command;
          type = "stdio";
        };
      }
      // lib.optionalAttrs cfg.stravaMcp.enable {
        strava = {
          args = [
            "-y"
            "@r-huijts/strava-mcp-server"
          ];
          command = "${pkgs.nodejs}/bin/npx";
          type = "stdio";
        };
      }
      // lib.optionalAttrs cfg.giteaMcp.enable {
        gitea-mcp = {
          command = "${config.shared.mcp.gitea.wrapper}/bin/gitea-mcp-wrapper";
          type = "stdio";
        };
      }
      // lib.optionalAttrs cfg.intervalsMcp.enable {
        intervals-icu = {
          command = "${intervalsMcpWrapper}/bin/intervals-mcp-wrapper";
          type = "stdio";
        };
      };
      package = claudeCodeWithEnv;
      settings = {
        alwaysThinkingEnabled = true;
        attribution = {
          commit = "";
          pr = "";
        };
        enabledPlugins = {
          "ossystems-commit@ossystems" = true;
        };
        # Plugin marketplace configuration
        extraKnownMarketplaces = {
          ossystems = {
            source = {
              repo = "OSSystems/claude-code-plugin";
              source = "github";
            };
          };
        };
        hooks = {
          Notification = [
            {
              hooks = [
                {
                  command = "${pkgs.libnotify}/bin/notify-send 'Claude Code' 'Session needs your attention' 2>/dev/null || true";
                  type = "command";
                }
              ];
              matcher = "";
            }
          ];
          PreToolUse = lib.mkIf cfg.rtk.enable [
            {
              hooks = [
                {
                  command = "${pkgs.rtk}/bin/rtk hook claude";
                  type = "command";
                }
              ];
              matcher = "Bash";
            }
          ];
          Stop = [
            {
              hooks = [
                {
                  command = "${pkgs.libnotify}/bin/notify-send 'Claude Code' 'Task finished' 2>/dev/null || true";
                  type = "command";
                }
              ];
            }
          ];
        };
        model = cfg.model;
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
        skipDangerousModePermissionPrompt = true;
      };
    };
    sops.secrets = lib.optionalAttrs cfg.intervalsMcp.enable {
      intervals-api-key.path = "${config.xdg.configHome}/secrets/intervals-api-key";
    };
  };
  options.home-manager.dev.claude-code = {
    agentBrowserExecutable = lib.mkOption {
      default = lib.optionalString isLinux "${pkgs.chromium}/bin/chromium";
      description = "Browser executable for agent-browser; empty when unavailable on the platform.";
      readOnly = true;
      type = lib.types.str;
    };
    anthropicBaseUrl = lib.mkOption {
      default = "http://192.168.150.11:4444";
      description = "Base URL for the Anthropic API.";
      type = lib.types.str;
    };
    enable = lib.mkEnableOption "Claude Code config" // {
      default = config.home-manager.dev.enable;
    };
    giteaMcp = {
      enable = lib.mkEnableOption "Gitea MCP server integration" // {
        default = true;
      };
    };
    intervalsMcp = {
      athleteId = lib.mkOption {
        default = "i537398";
        description = "intervals.icu athlete ID (format: iXXXXXX).";
        type = lib.types.str;
      };
      enable = lib.mkEnableOption "intervals.icu MCP server integration";
    };
    model = lib.mkOption {
      default = "claude-opus-5";
      description = "Default Claude Code model.";
      type = lib.types.str;
    };
    rtk = {
      enable = lib.mkEnableOption "RTK token-saving Bash proxy" // {
        default = true;
      };
    };
    stravaMcp = {
      enable = lib.mkEnableOption "Strava MCP server integration";
    };
  };
}
