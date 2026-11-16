# The appsignal package downloads its agent while compiling unless the agent files sit in its c_src,
# which it treats as a local release; agent.exs in the package lists the files and checksums.
{
  lib,
  fetchurl,
  system,
  dependencies,
}:
let
  appsignal = lib.findFirst (dependency: dependency.app == "appsignal") null dependencies;
  agentExs = builtins.readFile "${appsignal.source}/agent.exs";

  version = builtins.head (builtins.match ''.*def version, do: "([^"]+)".*'' agentExs);
  mirror = builtins.head (builtins.match ''.*def mirrors do[[:space:]]+\[[[:space:]]+"([^"]+)".*'' agentExs);
  triple =
    builtins.match ''.*"${system}" => %\{[[:space:]]+checksum: "([0-9a-f]{64})",[[:space:]]+filename: "([^"]+)".*''
      agentExs;

  agent = fetchurl {
    url = "${mirror}/${version}/${builtins.elemAt triple 1}";
    sha256 = builtins.head triple;
  };
in
{
  preConfigure = lib.optionalString (appsignal != null) ''
    tar -xzf ${agent} -C $MIX_DEPS_PATH/appsignal/c_src
  '';
}
