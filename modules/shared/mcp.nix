{ config, lib, pkgs, ... }:

let
  giteaCfg = config.shared.mcp.gitea;
  pencilExt = pkgs.pencil-vscode-extension;

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
      mcpPath = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = pencilExt.mcpPath;
        description = "Path to the pencil MCP server binary.";
      };

      mcpCommand = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        readOnly = true;
        default = [ pencilExt.mcpPath "--app" "vscodium" ];
        description = "Full command list for the pencil MCP server (binary + args).";
      };

      mcpArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        readOnly = true;
        default = [ "--app" "vscodium" ];
        description = "Command arguments for the pencil MCP server (excluding binary path).";
      };
    };
  };

  config = {
    sops.secrets.${giteaCfg.tokenSecretName} = { };
  };
}
