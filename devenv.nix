{ pkgs, lib, config, ... }:
let
  helpers = otp: elixir: import ./. { inherit pkgs lib otp elixir; };

  # builds a fixture release and runs its check/0 inside the release
  fixture =
    {
      otp,
      elixir,
      check,
      ...
    }@args:
    let
      app = (helpers otp elixir).mixRelease (
        removeAttrs args [ "otp" "elixir" "check" ] // { version = "1.2.3"; }
      );
    in
    pkgs.runCommand "${args.pname}-check" { } ''
      export HOME=$TMPDIR RELEASE_TMP=$TMPDIR RELEASE_COOKIE=check
      result=$(${app.bin} eval 'IO.puts(${check}.check())')
      echo "$result"
      [ "$result" = ok ]
      ln -s ${app.release} $out
    '';

  dev = (helpers "28" "1.19").dev;

  imageHelpers = helpers "28" "1.19";
  imageApp = imageHelpers.mixRelease {
    pname = "fx_prod";
    version = "1.2.3";
    root = ./fixtures/prod-runtime;
  };
in
{
  outputs.root-deploy = fixture {
    otp = "27";
    elixir = "1.18";
    check = "FxRoot";
    pname = "fx_root";
    root = ./fixtures/root-deploy;
    mixEnv = "deploy";
    extraConfig = [ ./fixtures/root-deploy/config/extra.exs ];
  };

  outputs.umbrella-subdir = fixture {
    otp = "28";
    elixir = "1.19";
    check = "FxB";
    pname = "fx_umbrella";
    root = ./fixtures/umbrella-subdir/umbrella;
    mixEnv = "deploy";
    release = "fx_umbrella";
  };

  outputs.prod-runtime = fixture {
    otp = "29";
    elixir = "1.20";
    check = "FxProd";
    pname = "fx_prod";
    root = ./fixtures/prod-runtime;
  };

  outputs.git-deps = fixture {
    otp = "28";
    elixir = "1.19";
    check = "FxGit";
    pname = "fx_git";
    root = ./fixtures/git-deps;
  };

  outputs.image = imageHelpers.image {
    name = "fx-prod";
    app = imageApp;
  };

  outputs.sbom = imageHelpers.sbom {
    name = "fx-prod";
    version = "1.2.3";
    image = config.outputs.image;
    mixLock = ./fixtures/prod-runtime/mix.lock;
  };

  languages.elixir = {
    enable = true;
    package = dev.elixir;
    lsp.enable = false;
  };

  env = {
    MIX_HOME = "${config.devenv.state}/mix";
    MIX_PATH = "${dev.hex}/lib/erlang/lib/hex/ebin";
    MIX_REBAR3 = lib.getExe dev.rebar3;
    MISE_DISABLE_TOOLS = "elixir,erlang";
  };
}
