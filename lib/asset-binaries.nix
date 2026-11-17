# esbuild and tailwind for the Mix packages, from the first package-lock.json that has them.
# Paths are relative to root.
{
  lib,
  root,
  npmDirs,
}:
let
  binary =
    package:
    let
      dir = lib.findFirst (
        dir: lib.hasInfix "\"node_modules/${package}\"" (builtins.readFile (root + "/${dir}/package-lock.json"))
      ) null npmDirs;
    in
    if dir == null then null else "${dir}/node_modules/.bin/${package}";
in
{
  esbuild = binary "esbuild";
  tailwind = binary "tailwindcss";
}
