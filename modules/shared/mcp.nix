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
  config = {
    sops.secrets.${giteaCfg.tokenSecretName} = { };
  };
  options.shared.mcp = {
    gitea = {
      host = lib.mkOption {
        default = defaultGiteaHost;
        description = "Gitea host URL used by the MCP server.";
        type = lib.types.str;
      };

      tokenSecretName = lib.mkOption {
        default = defaultGiteaTokenSecretName;
        description = "SOPS key name containing the Gitea PAT token.";
        type = lib.types.str;
      };

      wrapper = lib.mkOption {
        default = giteaWrapper;
        description = "The gitea-mcp-wrapper derivation.";
        readOnly = true;
        type = lib.types.package;
      };
    };

    pencil = {
      command = lib.mkOption {
        default =
          if pkgs.stdenv.hostPlatform.isLinux then "${pkgs.pencil-cli}/bin/pencil-mcp-bridge" else "";
        description = "Command that starts the pencil stdio MCP server (headless bridge).";
        readOnly = true;
        type = lib.types.str;
      };
    };
  };
}
