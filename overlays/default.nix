{ self, ... }:

final: prev: {

  zls = self.inputs.zls.packages.${prev.system}.default;

  deepcool-digital = prev.rustPlatform.buildRustPackage {
    pname = "deepcool-digital";
    version = "0.8.3-alpha";

    src = prev.fetchFromGitHub {
      owner = "Nortank12";
      repo = "deepcool-digital-linux";
      rev = "14e361ade3893d9bff53ffe3ac53758f41f595e5";
      hash = "sha256-Whmjd6NCOUkE7hM3FaN7grMwcC/suL7AJDVSgnZSKzM=";
    };

    nativeBuildInputs = [
      prev.pkg-config
    ];

    buildInputs = [ prev.systemd ];

    cargoHash = "sha256-K1pEbUyENPUS4QK0lztWmw8ov1fGrx8KHdODmSByfek=";
  };
}
