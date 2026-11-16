# Offline `npm ci` for every package-lock.json in the project, one fetchNpmDeps per directory,
# following nixpkgs' npmConfigHook, which only handles a single directory.
{
  lib,
  fetchNpmDeps,
  prefetch-npm-deps,
  nodejs,
  pname,
  root,
  hashes,
}:
let
  appAssetDirs =
    if builtins.pathExists (root + "/apps") then
      map (app: "apps/${app}/assets") (
        lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir (root + "/apps")))
      )
    else
      [ ];

  hasLock = dir: builtins.pathExists (root + "/${dir}/package-lock.json");
  found = lib.filter hasLock ([ "." "assets" ] ++ appAssetDirs);
  missing = lib.filter (dir: !(hashes ? ${dir})) found;
  withoutLock = lib.filter (dir: !(hasLock dir)) (lib.attrNames hashes);

  cacheFor =
    dir:
    fetchNpmDeps {
      name = "${pname}-npm-deps-${lib.replaceStrings [ "/" "." ] [ "-" "root" ] dir}";
      src = lib.fileset.toSource {
        root = root + "/${dir}";
        fileset = lib.fileset.unions [
          (root + "/${dir}/package.json")
          (root + "/${dir}/package-lock.json")
        ];
      };
      hash = hashes.${dir};
    };

  install = dir: ''
    (
      cd ${dir}
      cache=$TMPDIR/npm-cache-${builtins.hashString "md5" dir}
      export CACHE_MAP_PATH=$TMPDIR/npm-cache-map
      npmDeps=${cacheFor dir} prefetch-npm-deps --map-cache
      npmDeps=${cacheFor dir} prefetch-npm-deps --fixup-lockfile package-lock.json
      cp -r ${cacheFor dir} $cache
      chmod -R u+w $cache
      npm ci --ignore-scripts --cache $cache --offline --no-audit --no-fund
      patchShebangs node_modules
      npm rebuild --cache $cache --offline
      rm $CACHE_MAP_PATH
    )
  '';
in
assert lib.assertMsg (missing == [ ]) ''
  devenv-elixir: ${pname} needs npmDepsHashes for ${lib.concatStringsSep ", " missing}.
  Set npmDepsHashes."${builtins.head missing}" = ""; and the build prints the hash.'';
assert lib.assertMsg (withoutLock == [ ])
  "devenv-elixir: npmDepsHashes lists ${lib.concatStringsSep ", " withoutLock} without a package-lock.json";
{
  dirs = found;
  nativeBuildInputs = lib.optionals (found != [ ]) [
    nodejs
    prefetch-npm-deps
  ];
  script = lib.concatMapStrings install found;
}
