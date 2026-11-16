# esbuild and tailwind from nixpkgs for projects that configure them in config/config.exs; the
# tailwind major version follows the configured one, the rest follows nixpkgs.
{
  lib,
  esbuild,
  tailwindcss_3,
  tailwindcss_4,
  configExs,
}:
let
  configText = if builtins.pathExists configExs then builtins.readFile configExs else "";

  pinnedVersion =
    tool:
    let
      match = builtins.match ".*config :${tool},[[:space:]]+version: \"([^\"]+)\".*" configText;
    in
    if match == null then null else builtins.head match;

  tailwindVersion = pinnedVersion "tailwind";
in
{
  esbuild = if pinnedVersion "esbuild" == null then null else esbuild;
  tailwind =
    if tailwindVersion == null then
      null
    else if lib.versionOlder tailwindVersion "4" then
      tailwindcss_3
    else
      tailwindcss_4;
}
