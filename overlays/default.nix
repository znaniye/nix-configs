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
