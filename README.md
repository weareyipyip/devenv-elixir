# devenv-elixir

Nix helpers that build Elixir releases, images and SBOMs from a stock devenv setup.

## Use

```yaml
# devenv.yaml
inputs:
  devenv-elixir:
    url: github:weareyipyip/devenv-elixir/v1.0.0
    flake: false
```

```nix
# devenv.nix
{ pkgs, lib, config, inputs, ... }:
let
  elixir = import inputs.devenv-elixir { inherit pkgs lib; otp = "28"; elixir = "1.19"; };
  version = lib.trim (builtins.readFile ./VERSION);
  app = elixir.mixRelease { pname = "my_app"; inherit version; root = ./.; };
in
{
  outputs.deps = app.deps;
  outputs.release = app.release;
  outputs.image = elixir.image { name = "my-app"; inherit app; };
  outputs.sbom = elixir.sbom { name = "my-app"; inherit version; image = config.outputs.image; mixLock = ./mix.lock; };

  languages.elixir = {
    enable = true;
    package = elixir.dev.elixir;
    lsp.package = elixir.dev.elixir-ls;
  };
}
```

| Helper | Returns |
|---|---|
| `beam` | minimal BEAM set for releases |
| `dev` | BEAM set for the shell: the full set with wx on macOS, the same versions as `beam` |
| `assetEnv root` | `ERL_ZFLAGS` that point the esbuild and tailwind packages at the versions pinned in `config/config.exs` |
| `mixRelease { pname, version, root, mixEnv ? "prod", release ? null, extraConfig ? [ ], extraSources ? [ ], postBuild ? null, nativeBuildInputs ? [ ], buildInputs ? [ ] }` | `{ deps, release, name, bin }` |
| `image { name, app, entrypoint ? null, tag ? "latest", contents ? [ ], env ? [ ] }` | layered OCI image running as 65534 |
| `sbom { name, version, image, mixLock }` | CycloneDX JSON |

`mixRelease` details:

- **Config:** `config.exs` and `config/<mixEnv>.exs` go into the compiled deps layer; `runtime.exs` and `releases.exs` only into the release. Config files imported outside that convention go in `extraConfig`.
- **Sources:** `lib`, `priv`, `src`, `rel`, `apps` and `assets` under `root`, those that exist, plus `extraSources`.
- **Dependencies:** Hex and git dependencies come from `mix.lock`.
- **Version:** `version` replaces `0.0.0+development` in every `mix.exs`.
- **Assets:** with an `assets.deploy` alias the release runs it with esbuild and tailwind at the versions pinned in `config/config.exs`; other Phoenix apps get `mix phx.digest`.
- **Release name:** umbrellas pass `release`.

## esbuild and tailwind versions

`lib/asset-binaries.json` holds the hashes per version and platform. A project pinning a version that is not listed fails with the command that adds it:

```sh
scripts/add-asset-version tailwind 4.1.12
```

## Test

```sh
devenv build outputs.root-deploy outputs.umbrella-subdir outputs.prod-runtime outputs.git-deps outputs.mix-assets outputs.mix-assets-tw3 outputs.image outputs.sbom
```

Each fixture in `fixtures/` builds a release and runs its `check/0` inside it.
