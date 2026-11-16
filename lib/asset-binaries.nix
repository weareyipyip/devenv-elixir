# esbuild and tailwind binaries at the versions pinned in config/config.exs, so releases and the
# dev shell use what `mix esbuild.install` and `mix tailwind.install` would download.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  sigtool,
  configExs,
}:
let
  hashes = lib.importJSON ./asset-binaries.json;
  inherit (stdenv.hostPlatform) system;

  configText = if builtins.pathExists configExs then builtins.readFile configExs else "";

  pinnedVersion =
    tool:
    let
      match = builtins.match ".*config :${tool},[[:space:]]+version: \"([^\"]+)\".*" configText;
    in
    if match == null then null else builtins.head match;

  hashFor =
    tool: version:
    hashes.${tool}.${version}.${system} or (throw ''
      devenv-elixir: no hash for ${tool} ${version} on ${system}.
      Add it in the devenv-elixir repo with: scripts/add-asset-version ${tool} ${version}
    '');

  esbuildPlatforms = {
    aarch64-darwin = "darwin-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-linux = "linux-arm64";
    x86_64-linux = "linux-x64";
  };

  tailwindPlatforms = {
    aarch64-darwin = "macos-arm64";
    x86_64-darwin = "macos-x64";
    aarch64-linux = "linux-arm64";
    x86_64-linux = "linux-x64";
  };

  esbuild =
    version:
    let
      platform = esbuildPlatforms.${system};
    in
    stdenv.mkDerivation {
      pname = "esbuild";
      inherit version;
      src = fetchurl {
        url = "https://registry.npmjs.org/@esbuild/${platform}/-/${platform}-${version}.tgz";
        hash = hashFor "esbuild" version;
      };
      dontBuild = true;
      installPhase = "install -Dm755 bin/esbuild $out/bin/esbuild";
      meta.mainProgram = "esbuild";
    };

  # Tailwind 4 is a bun executable that needs the dynamic loader patched on Linux; any other
  # fixup changes the bytes, which breaks the macOS signature and Tailwind 3's embedded payload.
  tailwind =
    version:
    let
      isV3 = lib.versionOlder version "4";
      patchLinux = !isV3 && stdenv.hostPlatform.isLinux;
    in
    stdenv.mkDerivation {
      pname = "tailwindcss";
      inherit version;
      src = fetchurl {
        url = "https://github.com/tailwindlabs/tailwindcss/releases/download/v${version}/tailwindcss-${
          tailwindPlatforms.${system}
        }";
        hash = hashFor "tailwind" version;
      };
      dontUnpack = true;
      dontBuild = true;
      dontStrip = true;
      dontFixup = !patchLinux;
      nativeBuildInputs =
        lib.optionals patchLinux [
          autoPatchelfHook
          makeWrapper
        ]
        ++ lib.optional stdenv.hostPlatform.isDarwin sigtool;
      # some releases (4.1.12) ship a macOS signature that no longer matches, and macOS kills them
      installPhase = ''
        install -Dm755 $src $out/bin/tailwindcss
      ''
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        codesign --force --sign - $out/bin/tailwindcss
      '';
      postFixup = lib.optionalString patchLinux ''
        wrapProgram $out/bin/tailwindcss --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath [ stdenv.cc.cc.lib ]
        }
      '';
      meta.mainProgram = "tailwindcss";
    };

  esbuildVersion = pinnedVersion "esbuild";
  tailwindVersion = pinnedVersion "tailwind";
in
{
  esbuild = if esbuildVersion == null then null else esbuild esbuildVersion;
  tailwind = if tailwindVersion == null then null else tailwind tailwindVersion;
}
