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
    coreutils
    procps
    util-linux
    ;

  tarball = fetchurl {
    url = "https://registry.npmjs.org/@pencil.dev/cli/-/cli-${version}.tgz";
    hash = "sha256-fUXDZ60YETUozSE3rcXaSU/OBTx56WMpr9L8buNrBV4=";
  };

  manifest = ./pencil-cli/package.json;
  lockfile = ./pencil-cli/package-lock.json;

  pencil-cli = buildNpmPackage {
    pname = "pencil-cli";
    inherit version;
    src = tarball;

    postPatch = ''
      cp ${manifest} package.json
      cp ${lockfile} package-lock.json
    '';

    npmDeps = fetchNpmDeps {
      src = ./pencil-cli;
      hash = "sha256-X3raU/UGjxjMiitTEjpKYELsfsMoPjIHjgv2y4DPzBI=";
    };

    npmFlags = [
      "--omit=dev"
      "--ignore-scripts"
    ];
    dontNpmBuild = true;

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ unfreePkgs.stdenv.cc.cc.lib ];
    dontStrip = true;

    autoPatchelfIgnoreMissingDeps = [ "libtinfo.so.6" ];

    postInstall = ''
      ln -s $out/lib/node_modules/@pencil.dev/cli/dist/out/mcp-server-linux-x64 \
        $out/bin/pencil-mcp-server
    '';

    meta = {
      description = "Pencil.dev CLI — headless .pen design editor and stdio MCP server";
      homepage = "https://pencil.dev";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      license = lib.licenses.unfree;
      mainProgram = "pencil";
      platforms = [ "x86_64-linux" ];
    };
  };

  pencil-mcp-bridge = writeShellApplication {
    name = "pencil-mcp-bridge";
    runtimeInputs = [
      pencil-cli
      coreutils
      procps
      util-linux
    ];
    text = ''
      export PENCIL_APP_NAME=cli

      if [ -z "''${HOME:-}" ]; then
        echo "pencil-mcp-bridge: \$HOME is not set; cannot locate ~/.pencil." >&2
        exit 1
      fi
      pencil_home="$HOME/.pencil"
      sock="$pencil_home/socket/pencil-cli.sock"
      pidfile="$pencil_home/cli-host.pid"
      fifo="$pencil_home/cli-host.fifo"
      scratch="$pencil_home/cli-host-scratch.pen"
      logfile="$pencil_home/cli-host.log"
      lockfile="$pencil_home/cli-host.lock"
      designfile="$pencil_home/cli-host.design"

      if ! mkdir -p "$pencil_home/socket" 2>/dev/null; then
        echo "pencil-mcp-bridge: cannot create $pencil_home/socket (is \$HOME writable?)." >&2
        exit 1
      fi

      if [ -z "''${PENCIL_CLI_KEY:-}" ] && [ ! -f "$pencil_home/session-cli.json" ]; then
        echo "pencil-mcp-bridge: Pencil CLI is not authenticated." >&2
        echo "  Run 'pencil login' (or set PENCIL_CLI_KEY) so the headless editor can start." >&2
        exit 1
      fi

      desired_design=""
      if [ -n "''${PENCIL_DESIGN_FILE:-}" ]; then
        if [ -f "''${PENCIL_DESIGN_FILE}" ]; then
          desired_design="''${PENCIL_DESIGN_FILE}"
        else
          echo "pencil-mcp-bridge: PENCIL_DESIGN_FILE='$PENCIL_DESIGN_FILE' not found; using a blank canvas." >&2
        fi
      fi

      host_alive() {
        [ -S "$sock" ] || return 1
        local pid
        pid=$(cat "$pidfile" 2>/dev/null) || return 1
        [ -n "$pid" ] || return 1
        kill -0 "$pid" 2>/dev/null || return 1
        grep -qaE "index\.(cjs|mjs)" "/proc/$pid/cmdline" 2>/dev/null
      }

      host_serves_desired() {
        [ "$(cat "$designfile" 2>/dev/null || true)" = "$desired_design" ]
      }

      stop_host() {
        local pid
        pid=$(cat "$pidfile" 2>/dev/null || true)
        if [ -n "$pid" ]; then
          kill "$pid" 2>/dev/null || true
        fi
        rm -f "$sock" "$pidfile" "$designfile"
      }

      start_host() {
        exec 9>"$lockfile"
        if ! flock -w 30 9; then
          echo "pencil-mcp-bridge: timed out acquiring the startup lock $lockfile." >&2
          return 1
        fi

        if host_alive && host_serves_desired; then
          exec 9>&-
          return 0
        fi

        stop_host
        [ -p "$fifo" ] || {
          rm -f "$fifo"
          mkfifo "$fifo"
        }

        local args=(interactive -o "$scratch")
        if [ -n "$desired_design" ]; then
          args=(interactive -i "$desired_design" -o "$scratch")
        fi

        setsid pencil "''${args[@]}" 0<>"$fifo" 9>&- >"$logfile" 2>&1 &
        echo $! >"$pidfile"
        printf '%s' "$desired_design" >"$designfile"

        local i=0
        until [ -S "$sock" ]; do
          sleep 0.3
          i=$((i + 1))
          local pid
          pid=$(cat "$pidfile" 2>/dev/null || true)
          if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
            echo "pencil-mcp-bridge: headless host exited during startup; tail of $logfile:" >&2
            tail -n 5 "$logfile" >&2 || true
            return 1
          fi
          if [ "$i" -ge 100 ]; then
            echo "pencil-mcp-bridge: headless host did not come up within 30s; see $logfile" >&2
            return 1
          fi
        done

        exec 9>&-
      }

      if ! { host_alive && host_serves_desired; }; then
        start_host
      fi
      exec pencil-mcp-server -app cli
    '';
  };
in
unfreePkgs.symlinkJoin {
  name = "pencil-cli-${version}";
  paths = [
    pencil-cli
    pencil-mcp-bridge
  ];
  passthru.penSchemaVersion = "2.13";
  meta = pencil-cli.meta // {
    description = "Pencil.dev CLI, headless MCP bridge, and stdio MCP server";
  };
}
