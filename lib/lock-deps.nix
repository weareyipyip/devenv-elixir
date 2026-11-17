# Fetches every dependency in mix.lock into one deps directory, ready for mixRelease.
#
# Hex lines end with the sha256 of the package tarball and git lines hold the commit, so
# mix.lock stays the only place where versions and hashes live.
{
  lib,
  runCommand,
  beam,
  name,
  mixLock,
}:
let
  lockLines = lib.splitString "\n" (builtins.readFile mixLock);
  dependencyLines = lib.filter (lib.hasPrefix "  \"") lockLines;

  #   "app": {:hex, :package, "1.2.3", "<inner checksum>", [:mix], [...], "hexpm", "<tarball sha256>"},
  hexPattern = ''[[:space:]]*"([a-z0-9_]+)": \{:hex, :([a-z0-9_]+), "([^"]+)", .*, "hexpm", "([0-9a-f]{64})"},?'';
  #   "app": {:git, "https://github.com/owner/repo.git", "<40 char commit>", [tag: "v1.0", ...]},
  gitPattern = ''[[:space:]]*"([a-z0-9_]+)": \{:git, "([^"]+)", "([0-9a-f]{40})", [[](.*)[]]},?'';

  fetchDependency =
    line:
    let
      hex = builtins.match hexPattern line;
      git = builtins.match gitPattern line;
      app = builtins.head (builtins.match ''[[:space:]]*"([a-z0-9_]+)".*'' line);
    in
    if hex != null then
      {
        app = builtins.elemAt hex 0;
        version = builtins.elemAt hex 2;
        source = beam.fetchHex {
          pkg = builtins.elemAt hex 1;
          version = builtins.elemAt hex 2;
          sha256 = builtins.elemAt hex 3;
        };
      }
    else if git != null then
      {
        app = builtins.elemAt git 0;
        # Mix only treats a git dependency as checked out when .git/HEAD exists
        gitHead = builtins.elemAt git 2;
        source = builtins.fetchGit {
          url = builtins.elemAt git 1;
          rev = builtins.elemAt git 2;
          # a tag or branch commit is not always reachable from the default branch
          allRefs = true;
          submodules = lib.hasInfix "submodules: true" (builtins.elemAt git 3);
        };
      }
    else
      throw "devenv-elixir: mix.lock entry ${app} is neither a public Hex package nor a git dependency";

  dependencies = map fetchDependency dependencyLines;
in
{
  inherit dependencies;

  # app names, for picking build steps that depend on a dependency
  names = map (dependency: dependency.app) dependencies;

  # copies, not symlinks: mixRelease copies this directory with cp -R and compiles in place
  directory = runCommand "${name}-mix-deps" { } ''
    mkdir $out
    ${lib.concatMapStrings (
      dependency:
      "cp -r ${dependency.source} $out/${dependency.app}\n"
      + lib.optionalString (dependency ? gitHead) ''
        chmod u+w $out/${dependency.app}
        mkdir $out/${dependency.app}/.git
        echo ${dependency.gitHead} > $out/${dependency.app}/.git/HEAD
      ''
    ) dependencies}
  '';
}
