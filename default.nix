# Nix helpers for Elixir apps in devenv. Import with the OTP major and Elixir minor version:
#
#   elixir = import inputs.devenv-elixir { inherit pkgs lib; otp = "28"; elixir = "1.19"; };
{
  pkgs,
  lib,
  otp,
  elixir,
}:
let
  beamSets = lib.filter (name: builtins.match "beamMinimal[0-9]+Packages" name != null) (
    builtins.attrNames pkgs
  );
  supportedOtps = map (name: lib.removeSuffix "Packages" (lib.removePrefix "beamMinimal" name)) beamSets;

  elixirAttribute = "elixir_" + lib.replaceStrings [ "." ] [ "_" ] elixir;

  withElixir =
    set:
    let
      versions = lib.filter (name: builtins.match "elixir_1_[0-9]+" name != null) (builtins.attrNames set);
    in
    assert lib.assertMsg (builtins.match "1\\.[0-9]+" elixir != null)
      "devenv-elixir: elixir must be a minor version such as \"1.19\", not \"${elixir}\"";
    assert lib.assertMsg (set ? ${elixirAttribute})
      "devenv-elixir: Elixir ${elixir} is not available for OTP ${otp} in this nixpkgs; available: ${
        lib.concatMapStringsSep ", " (lib.replaceStrings [ "elixir_" "_" ] [ "" "." ]) versions
      }";
    set.overrideScope (final: prev: { elixir = prev.${elixirAttribute}; });

  # the regular set builds epmd with systemd, which pulls systemd, curl and libssh2 into the release
  beam =
    assert lib.assertMsg (pkgs ? "beamMinimal${otp}Packages")
      "devenv-elixir: OTP ${otp} is not in this nixpkgs; available: ${lib.concatStringsSep ", " supportedOtps}";
    withElixir pkgs."beamMinimal${otp}Packages";

  # on macOS the regular set, whose wx makes :observer work
  dev =
    let
      candidate = if pkgs.stdenv.isDarwin then withElixir pkgs."beam${otp}Packages" else beam;
    in
    assert lib.assertMsg (
      candidate.erlang.version == beam.erlang.version && candidate.elixir.version == beam.elixir.version
    ) "devenv-elixir: the shell and the release must use the same Erlang and Elixir versions";
    candidate;

  existing = lib.filter builtins.pathExists;

  assetBinariesFor =
    root:
    import ./lib/asset-binaries.nix {
      inherit lib;
      inherit (pkgs)
        stdenv
        fetchurl
        autoPatchelfHook
        makeWrapper
        ;
      inherit (pkgs.darwin) sigtool;
      configExs = root + "/config/config.exs";
    };

  # The esbuild and tailwind packages only read config :esbuild/:tailwind, :path, which no project
  # sets, so the path goes in as application env through erl flags. Erlang strips unescaped quotes.
  assetEnvFor =
    binaries:
    let
      flags = lib.concatStringsSep " " (
        lib.optional (binaries.esbuild != null) ''-esbuild path <<\"${lib.getExe binaries.esbuild}\">>''
        ++ lib.optional (binaries.tailwind != null) ''-tailwind path <<\"${lib.getExe binaries.tailwind}\">>''
      );
    in
    lib.optionalAttrs (flags != "") { ERL_ZFLAGS = flags; };

  # ERL_ZFLAGS that point esbuild and tailwind at the versions pinned in config/config.exs
  assetEnv = root: assetEnvFor (assetBinariesFor root);

  # Returns { deps, release, name, bin }. deps holds the compiled dependencies and only rebuilds
  # when mix.exs, mix.lock or the compile-time config changes, so CI can cache it.
  mixRelease =
    {
      pname,
      version,
      root,
      mixEnv ? "prod",
      release ? null,
      extraConfig ? [ ],
      extraSources ? [ ],
      postBuild ? null,
      npmDepsHashes ? { },
      nodejs ? pkgs.nodejs,
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
    }:
    let
      npmDeps = import ./lib/npm-deps.nix {
        inherit lib nodejs pname root;
        inherit (pkgs) fetchNpmDeps prefetch-npm-deps;
        hashes = npmDepsHashes;
      };

      mixExs = builtins.readFile (root + "/mix.exs");
      isUmbrella = lib.hasInfix "apps_path:" mixExs;
      appMatches = lib.filter (match: match != null) (
        map (builtins.match "[[:space:]]*app: :([a-z0-9_]+),?") (lib.splitString "\n" mixExs)
      );
      appMatch = if appMatches == [ ] then null else builtins.head appMatches;

      name =
        if release != null then
          release
        else if isUmbrella || appMatch == null then
          throw "devenv-elixir: ${pname} is an umbrella, so mixRelease needs the release name"
        else
          builtins.head appMatch;

      lockDeps = import ./lib/lock-deps.nix {
        inherit lib beam;
        inherit (pkgs) runCommand;
        name = pname;
        mixLock = root + "/mix.lock";
      };

      precompiledNifs = import ./lib/precompiled-nifs.nix {
        inherit lib;
        inherit (pkgs) fetchurl linkFarm;
        inherit (pkgs.stdenv.hostPlatform) system;
        name = pname;
        inherit (lockDeps) dependencies;
      };

      appsignalAgent = import ./lib/appsignal-agent.nix {
        inherit lib;
        inherit (pkgs) fetchurl;
        inherit (pkgs.stdenv.hostPlatform) system;
        inherit (lockDeps) dependencies;
      };

      config = file: root + "/config/${file}";
      compileConfig = existing [
        (config "config.exs")
        (config "${mixEnv}.exs")
      ];
      runtimeConfig = existing [
        (config "runtime.exs")
        (config "releases.exs")
      ];
      umbrellaMixFiles = lib.optional (builtins.pathExists (root + "/apps")) (
        lib.fileset.fileFilter (file: file.name == "mix.exs") (root + "/apps")
      );

      depsFiles = [
        (root + "/mix.exs")
        (root + "/mix.lock")
      ]
      ++ compileConfig
      ++ extraConfig
      ++ umbrellaMixFiles;

      appFiles =
        runtimeConfig
        ++ existing (
          map (dir: root + "/${dir}") [
            "lib"
            "priv"
            "src"
            "rel"
            "apps"
            "assets"
            "package.json"
            "package-lock.json"
          ]
        )
        ++ extraSources;

      toSource =
        files:
        lib.fileset.toSource {
          inherit root;
          fileset = lib.fileset.unions files;
        };

      assetBinaries = assetBinariesFor root;

      # deps.loadpaths runs once per mix invocation, so the alias's tasks skip the deps check
      defaultPostBuild =
        if lib.hasInfix "\"assets.deploy\"" mixExs then
          ''
            ${lib.concatStrings (lib.mapAttrsToList (name: value: "export ${name}='${value}'\n") (assetEnvFor assetBinaries))}
            mix do deps.loadpaths --no-deps-check + assets.deploy
          ''
        else if builtins.elem "phoenix" lockDeps.names then
          ''
            mkdir -p priv/static
            mix phx.digest --no-deps-check
          ''
        else
          "";

      deps = beam.mixRelease {
        pname = "${pname}-deps";
        version = "0";
        inherit mixEnv nativeBuildInputs buildInputs;
        mixFodDeps = lockDeps.directory;
        env = precompiledNifs.env;
        inherit (appsignalAgent) preConfigure;
        src = toSource depsFiles;
        buildPhase = "true";
        # deps such as appsignal write into deps/<app>/priv, which _build only links to
        installPhase = ''
          cp -r _build $out
          find _build -name priv -type l | while read -r link; do
            rm "$out/''${link#_build/}"
            cp -r "$(readlink -f "$link")" "$out/''${link#_build/}"
          done
        '';
        dontFixup = true;
      };

      releaseDrv = beam.mixRelease {
        inherit
          pname
          version
          mixEnv
          buildInputs
          ;
        nativeBuildInputs = nativeBuildInputs ++ npmDeps.nativeBuildInputs;
        mixReleaseName = lib.optionalString (release != null) release;
        mixFodDeps = lockDeps.directory;
        env = precompiledNifs.env;
        src = toSource (depsFiles ++ appFiles);
        dontMixDepsCompile = true;
        # the version lives in VERSION; mix.exs files hold this placeholder
        preBuild = ''
          { grep -rlF --include=mix.exs "0.0.0+development" . || true; } | while read -r file; do
            substituteInPlace "$file" --replace-fail "0.0.0+development" "${version}"
          done
          cp -r ${deps}/. _build
          chmod -R u+w _build
          ${npmDeps.script}
        '';
        postBuild = if postBuild == null then defaultPostBuild else postBuild;
        # tzdata updates itself by writing into its priv dir, which is read-only in the Nix store;
        # an autoupdate setting from the project's config wins
        postInstall = lib.optionalString (builtins.elem "tzdata" lockDeps.names) ''
          for config in $out/releases/*/sys.config; do
            erl -noshell -eval '
              [File] = init:get_plain_arguments(),
              {ok, [Config]} = file:consult(File),
              Tzdata = proplists:get_value(tzdata, Config, []),
              Patched = case lists:keymember(autoupdate, 1, Tzdata) of
                true -> Config;
                false -> lists:keystore(tzdata, 1, Config, {tzdata, [{autoupdate, disabled} | Tzdata]})
              end,
              ok = file:write_file(File, io_lib:format("~tp.~n", [Patched])),
              halt().' -extra "$config"
          done
        '';
      };
    in
    {
      inherit deps name;
      release = releaseDrv;
      bin = "${releaseDrv}/bin/${name}";
    };

  # Non-root layered image. Without an entrypoint the container runs `bin/<release> start`.
  image =
    {
      name,
      app,
      entrypoint ? null,
      tag ? "latest",
      contents ? [ ],
      env ? [ ],
    }:
    let
      application = pkgs.linkFarm "${name}-application" (
        {
          "application/bin/${app.name}" = app.bin;
        }
        // lib.optionalAttrs (entrypoint != null) {
          "application/${baseNameOf entrypoint}" = entrypoint;
        }
      );
    in
    pkgs.dockerTools.buildLayeredImage {
      inherit name tag;
      compressor = "none";
      contents = [
        application
        pkgs.coreutils
        pkgs.dockerTools.binSh
        pkgs.dockerTools.caCertificates
      ]
      ++ contents;
      extraCommands = "mkdir -m 1777 tmp";
      config = {
        User = "65534:65534";
        WorkingDir = "/application";
        Entrypoint = [
          (
            if entrypoint != null then
              "/application/${baseNameOf entrypoint}"
            else
              "/application/bin/${app.name}"
          )
        ];
        Cmd = [ "start" ];
        Env = [
          "HOME=/tmp"
          "RELEASE_TMP=/tmp"
          "LANG=C.UTF-8"
        ]
        ++ env;
      };
    };

  # syft finds the OTP applications in the image; relabel.jq marks the mix.lock ones as Hex
  # packages and fixes the CPEs of Nix packages
  sbom =
    {
      name,
      version,
      image,
      mixLock,
    }:
    pkgs.runCommand "${name}-sbom.cdx.json"
      {
        nativeBuildInputs = [
          pkgs.syft
          pkgs.jq
        ];
        SYFT_CHECK_FOR_APP_UPDATE = "false";
      }
      ''
        export HOME=$TMPDIR
        syft scan docker-archive:${image} \
          --select-catalogers +erlang-otp-application-cataloger \
          --source-name ${name} --source-version ${version} \
          --quiet -o cyclonedx-json=sbom.json
        jq --rawfile lock ${mixLock} -f ${./lib/relabel.jq} sbom.json > $out
      '';
in
{
  inherit
    beam
    dev
    assetEnv
    mixRelease
    image
    sbom
    ;
}
