# node_modules for every package-lock.json in the project, installed from the lockfile's own
# resolved URLs and integrity hashes, so there is nothing to keep up to date besides the lockfile.
{
  lib,
  importNpmLock,
  nodejs,
  root,
}:
let
  appAssetDirs =
    if builtins.pathExists (root + "/apps") then
      map (app: "apps/${app}/assets") (
        lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir (root + "/apps")))
      )
    else
      [ ];

  dirs = lib.filter (dir: builtins.pathExists (root + "/${dir}/package-lock.json")) (
    [
      "."
      "assets"
    ]
    ++ appAssetDirs
  );

  install = dir: ''
    cp -r ${importNpmLock.buildNodeModules { npmRoot = root + "/${dir}"; inherit nodejs; }}/node_modules ${dir}/
    chmod -R u+w ${dir}/node_modules
  '';
in
{
  inherit dirs;
  nativeBuildInputs = lib.optional (dirs != [ ]) nodejs;
  script = lib.concatMapStrings install dirs;
}
