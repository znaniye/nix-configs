{ self, ... }:

final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  inherit (self.inputs.emacs-overlay.packages.${system}) emacsWithPackagesFromUsePackage;
  inherit (self.inputs.niri.packages.${system}) niri-unstable;

  zls = self.inputs.zls.packages.${system}.default;
  zig = self.inputs.zig.packages.${system}."0.15.1";

  opencode = self.inputs.opencode.packages.${system}.opencode;

  pi-coding-agent = self.inputs.coding-agents.packages.${system}.pi-coding-agent;

  pencil-vscode-extension =
    let
      pencilMcpBinaryName =
        if prev.stdenv.hostPlatform.isAarch64 then
          "mcp-server-linux-arm64"
        else
          "mcp-server-linux-x64";
      base = prev.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "pencildev";
          publisher = "highagency";
          version = "0.6.38";
          hash = "sha256-SpmKjxBttOdMCrPCxvXp93ZnS+UAd0vRxAOx0BSKIuc=";
        };
      };
      patched = base.overrideAttrs (oldAttrs: {
        postFixup = (oldAttrs.postFixup or "") + ''
          mcpBinary="$out/share/vscode/extensions/highagency.pencildev/out/${pencilMcpBinaryName}"
          if [ -f "$mcpBinary" ]; then
            mv "$mcpBinary" "$mcpBinary.real"
            cat > "$mcpBinary" <<EOF
          #!${prev.bash}/bin/bash
          exec ${prev.stdenv.cc.bintools.dynamicLinker} --library-path ${
            prev.lib.makeLibraryPath [ prev.glibc ]
          } "$mcpBinary.real" "\$@"
          EOF
            chmod +x "$mcpBinary"
          fi
        '';
        passthru = (oldAttrs.passthru or { }) // {
          mcpPath = "${patched}/share/vscode/extensions/highagency.pencildev/out/${pencilMcpBinaryName}";
        };
      });
    in
    patched;

  # aiohttp 3.13.4 rejects duplicate 'Server' headers (RFC 9110 strict check),
  # breaking aioboto3 tests that use moto+werkzeug. Fixed in 3.13.5.
  # https://github.com/aio-libs/aiohttp/issues/12297
  pythonPackagesOverlay = _pyFinal: pyPrev: {
    aiohttp = pyPrev.aiohttp.overridePythonAttrs {
      version = "3.13.5";
      src = prev.fetchFromGitHub {
        owner = "aio-libs";
        repo = "aiohttp";
        tag = "v3.13.5";
        hash = "sha256-bAP1/a2COHbe+39KY3GHXSo1Iq9x9xX8O2mLhmFlMlE=";
      };
    };
  };

  python3Packages = prev.python3Packages.overrideScope final.pythonPackagesOverlay;
  python3 = prev.python3.override { packageOverrides = final.pythonPackagesOverlay; };

}
