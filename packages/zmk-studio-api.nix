{ pkgs }:
let
  inherit (pkgs) lib;

  version = "0.5.0";

  src = pkgs.fetchFromGitHub {
    hash = "sha256-WTzhcpE2GybzD1tBEMeLn3WXnl4N2DHCGM7GrHRydrQ=";
    owner = "srwi";
    repo = "zmk-studio-api";
    rev = "95437fc138458d73c91d382096cbdc78f7931361";
  };
in
pkgs.python3Packages.buildPythonPackage {
  inherit version src;
  buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs.dbus
    pkgs.udev
  ];
  cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-1al0tw2yToQPtvaAOPFephPKskAqMr0GsCtHxExpMPg=";
  };
  meta = {
    description = "Rust + Python client for the ZMK Studio RPC API (serial + BLE)";
    homepage = "https://github.com/srwi/zmk-studio-api";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.rustPlatform.cargoSetupHook
    pkgs.rustPlatform.maturinBuildHook
    pkgs.cargo
    pkgs.rustc
  ];
  pname = "zmk-studio-api";
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'features = ["python", "serial"]' \
                     'features = ["python", "serial", "ble"]'

    substituteInPlace build.rs \
      --replace-fail 'protoc_bin_vendored::protoc_bin_path().expect("failed to get protoc binary path")' \
                     'std::path::PathBuf::from("${pkgs.protobuf}/bin/protoc")'
  '';
  pyproject = true;
  pythonImportsCheck = [ "zmk_studio_api" ];
}
