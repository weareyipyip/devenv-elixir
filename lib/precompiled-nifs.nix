# Prebuilt NIFs that elixir_make and rustler_precompiled would download at compile time, fetched
# by the checksums the packages ship and offered through their cache directories.
{
  lib,
  fetchurl,
  linkFarm,
  system,
  name,
  dependencies,
}:
let
  releases = {
    mdex_native = "leandrocp/mdex_native";
    vix = "akash-akya/vix";
  };

  # elixir_make names targets like aarch64-linux-gnu, Rust like aarch64-unknown-linux-gnu
  targets =
    {
      aarch64-darwin = [ "aarch64-apple-darwin" ];
      x86_64-darwin = [ "x86_64-apple-darwin" ];
      aarch64-linux = [
        "aarch64-linux-gnu"
        "aarch64-unknown-linux-gnu"
      ];
      x86_64-linux = [
        "x86_64-linux-gnu"
        "x86_64-unknown-linux-gnu"
      ];
    }
    .${system};

  isForTarget =
    file: lib.any (target: lib.hasInfix "-${target}-" file || lib.hasInfix "-${target}." file) targets;

  # others, such as lazy_html, are only used in tests; the build error names any that is missing
  known = lib.filter (dependency: releases ? ${dependency.app}) dependencies;

  artifacts =
    dependency:
    let
      checksumFile = lib.findFirst (
        file: builtins.match "checksum.*\\.exs" file != null
      ) (throw "devenv-elixir: ${dependency.app} has no checksum file") (
        lib.attrNames (builtins.readDir dependency.source)
      );
      #   "vix-nif-2.16-aarch64-apple-darwin-0.41.0.tar.gz" => "sha256:<hex>",
      entries = lib.filter (entry: entry != null) (
        map (builtins.match ''[[:space:]]*"([^"]+)" => "sha256:([0-9a-f]{64})",?'') (
          lib.splitString "\n" (builtins.readFile "${dependency.source}/${checksumFile}")
        )
      );
      forTarget = lib.filter (entry: isForTarget (builtins.head entry)) entries;
    in
    map (entry: {
      name = builtins.head entry;
      path = fetchurl {
        url = "https://github.com/${releases.${dependency.app}}/releases/download/v${dependency.version}/${builtins.head entry}";
        sha256 = builtins.elemAt entry 1;
        name = builtins.head entry;
      };
    }) forTarget;

  cache = linkFarm "${name}-precompiled-nifs" (lib.concatMap artifacts known);
in
{
  env = lib.optionalAttrs (known != [ ]) {
    ELIXIR_MAKE_CACHE_DIR = "${cache}";
    RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH = "${cache}";
  };
}
