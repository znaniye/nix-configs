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
      ${lib.optionalString cfg.claudish.enable ''
        export CLAUDISH_PROVIDER="anthropic"
        export CLAUDISH_MODEL="${cfg.claudish.model}"
        export CLAUDISH_ANTHROPIC_URL="${cfg.anthropicBaseUrl}"
      ''}
      if [ -f "${config.sops.secrets.anthropic-auth-token.path}" ]; then
        export ANTHROPIC_AUTH_TOKEN="\$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.anthropic-auth-token.path})"
        ${lib.optionalString cfg.claudish.enable ''export CLAUDISH_ANTHROPIC_KEY="\$ANTHROPIC_AUTH_TOKEN"''}
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
      default = "claude-opus-5";
      description = "Default Claude Code model.";
    };

    anthropicBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://192.168.150.11:4444";
      description = "Base URL for the Anthropic API.";
    };

    agentBrowserExecutable = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = lib.optionalString isLinux "${pkgs.chromium}/bin/chromium";
      description = "Browser executable for agent-browser; empty when unavailable on the platform.";
    };

    giteaMcp = {
      enable = lib.mkEnableOption "Gitea MCP server integration" // {
        default = true;
      };
    };

    stravaMcp = {
      enable = lib.mkEnableOption "Strava MCP server integration";
    };

    intervalsMcp = {
      enable = lib.mkEnableOption "intervals.icu MCP server integration";

      athleteId = lib.mkOption {
        type = lib.types.str;
        default = "i537398";
        description = "intervals.icu athlete ID (format: iXXXXXX).";
      };
    };

    rtk = {
      enable = lib.mkEnableOption "RTK token-saving Bash proxy" // {
        default = true;
      };
    };

    claudish = {
      enable = lib.mkEnableOption "claudish-to-english plain-English rewrites" // {
        default = true;
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "claude-haiku-4-5";
        description = "Model used for the plain-English rewrites, as named by the Anthropic base URL.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        jq
        curl
        agent-browser
      ])
      ++ lib.optional isLinux pkgs.chromium
      ++ lib.optional cfg.rtk.enable pkgs.rtk;

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

    nixpkgs = {
      config.allowUnfreePredicate =
        pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "claude-code"
          "claude"
        ];
    };

    sops.secrets = lib.optionalAttrs cfg.intervalsMcp.enable {
      intervals-api-key.path = "${config.xdg.configHome}/secrets/intervals-api-key";
    };

    programs.claude-code = {
      enable = true;
      package = claudeCodeWithEnv;
      mcpServers = {
      }
      // lib.optionalAttrs isLinux {
        pencil = {
          type = "stdio";
          command = config.shared.mcp.pencil.command;
        };
      }
      // lib.optionalAttrs cfg.stravaMcp.enable {
        strava = {
          type = "stdio";
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@r-huijts/strava-mcp-server"
          ];
        };
      }
      // lib.optionalAttrs cfg.giteaMcp.enable {
        gitea-mcp = {
          type = "stdio";
          command = "${config.shared.mcp.gitea.wrapper}/bin/gitea-mcp-wrapper";
        };
      }
      // lib.optionalAttrs cfg.intervalsMcp.enable {
        intervals-icu = {
          type = "stdio";
          command = "${intervalsMcpWrapper}/bin/intervals-mcp-wrapper";
        };
      };
      agents = lib.mapAttrs (
        name: agent: config.shared.codingAgents.renderClaudeAgent name agent
      ) config.shared.codingAgents.agents;
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
        }
        // lib.optionalAttrs cfg.claudish.enable {
          gvzdv-plugins = {
            source = {
              source = "github";
              repo = "gvzdv/claudish-to-english";
            };
          };
        };

        enabledPlugins = {
          "ossystems-commit@ossystems" = true;
        }
        // lib.optionalAttrs cfg.claudish.enable {
          "claudish-to-english@gvzdv-plugins" = true;
        };
      };
    };
  };
}
