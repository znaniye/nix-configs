{
  config,
  lib,
  pkgs,
  ...
}:

let
  giteaCfg = config.shared.mcp.gitea;

  defaultGiteaHost = "http://192.168.68.111:3000";
  defaultGiteaTokenSecretName = "gitea-pat-token";

  giteaWrapper = pkgs.writeShellScriptBin "gitea-mcp-wrapper" ''
    TOKEN=$(cat ${config.sops.secrets.${giteaCfg.tokenSecretName}.path})
    exec ${pkgs.gitea-mcp-server}/bin/gitea-mcp \
      -host "${giteaCfg.host}" \
      -token "$TOKEN" \
      "$@"
  '';
in
{
  options.shared.mcp = {
    gitea = {
      host = lib.mkOption {
        type = lib.types.str;
        default = defaultGiteaHost;
        description = "Gitea host URL used by the MCP server.";
      };

      tokenSecretName = lib.mkOption {
        type = lib.types.str;
        default = defaultGiteaTokenSecretName;
        description = "SOPS key name containing the Gitea PAT token.";
      };

      wrapper = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        default = giteaWrapper;
        description = "The gitea-mcp-wrapper derivation.";
      };
    };

    pencil = {
      command = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "${pkgs.pencil-cli}/bin/pencil-mcp-bridge";
        description = "Command that starts the pencil stdio MCP server (headless bridge).";
      };
    };
  };

  config = {
    sops.secrets.${giteaCfg.tokenSecretName} = { };
  };
}
