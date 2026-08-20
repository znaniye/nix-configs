{ pkgs }:
let
  version = "0.2.8";

  unfreePkgs = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  inherit (unfreePkgs)
    lib
    buildNpmPackage
    fetchurl
    fetchNpmDeps
    autoPatchelfHook
    writeShellApplication
    ;

  tarball = fetchurl {
    hash = "sha256-fUXDZ60YETUozSE3rcXaSU/OBTx56WMpr9L8buNrBV4=";
    url = "https://registry.npmjs.org/@pencil.dev/cli/-/cli-${version}.tgz";
  };

  manifest = ./package.json;
  lockfile = ./package-lock.json;

  pencil-cli = buildNpmPackage {
    inherit version;
    autoPatchelfIgnoreMissingDeps = [ "libtinfo.so.6" ];
    buildInputs = [ unfreePkgs.stdenv.cc.cc.lib ];
    dontNpmBuild = true;
    dontStrip = true;
    meta = {
      description = "Pencil.dev CLI — headless .pen design editor and stdio MCP server";
      homepage = "https://pencil.dev";
      license = lib.licenses.unfree;
      mainProgram = "pencil";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
    nativeBuildInputs = [ autoPatchelfHook ];
    npmDeps = fetchNpmDeps {
      hash = "sha256-X3raU/UGjxjMiitTEjpKYELsfsMoPjIHjgv2y4DPzBI=";
      src = ./.;
    };
    npmFlags = [
      "--omit=dev"
      "--ignore-scripts"
    ];
    pname = "pencil-cli";
    postInstall = ''
      ln -s $out/lib/node_modules/@pencil.dev/cli/dist/out/mcp-server-linux-x64 \
        $out/bin/pencil-mcp-server
    '';
    postPatch = ''
      cp ${manifest} package.json
      cp ${lockfile} package-lock.json
    '';
    src = tarball;
  };

  pencil-mcp-bridge = writeShellApplication {
    name = "pencil-mcp-bridge";
    runtimeInputs = [
      pencil-cli
      unfreePkgs.iproute2
    ];
    text = ''
      if [ -z "''${HOME:-}" ]; then
        echo "pencil-mcp-bridge: \$HOME is not set; cannot locate ~/.pencil." >&2
        exit 1
      fi

      sockdir="$HOME/.pencil/socket"
      live=""
      for app in vscodium desktop; do
        sock="$sockdir/pencil-$app.sock"
        if [ -S "$sock" ] && ss -xlH 2>/dev/null | grep -Fq "$sock"; then
          live="$app"
          break
        fi
      done

      if [ -z "$live" ]; then
        echo "pencil-mcp-bridge: no live Pencil editor found under $sockdir." >&2
        echo "  Open your .pen document in the Pencil VSCodium extension (or desktop app)," >&2
        echo "  then start the agent so the MCP attaches to it." >&2
        exit 1
      fi

      exec pencil-mcp-server -app "$live"
    '';
  };
in
unfreePkgs.symlinkJoin {
  meta = pencil-cli.meta // {
    description = "Pencil.dev CLI, headless MCP bridge, and stdio MCP server";
  };
  name = "pencil-cli-${version}";
  passthru.penSchemaVersion = "2.13";
  paths = [
    pencil-cli
    pencil-mcp-bridge
  ];
}
