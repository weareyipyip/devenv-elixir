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
| `assetEnv root` | `ERL_ZFLAGS` that point the esbuild and tailwind packages at the nixpkgs binaries the release uses |
| `mixRelease { pname, version, root, mixEnv ? "prod", release ? null, extraConfig ? [ ], extraSources ? [ ], postBuild ? null, nodejs ? pkgs.nodejs, nativeBuildInputs ? [ ], buildInputs ? [ ] }` | `{ deps, release, name, bin }` |
| `image { name, app, entrypoint ? null, tag ? "latest", contents ? [ ], env ? [ ] }` | layered OCI image running as 65534 |
| `sbom { name, version, image, mixLock }` | CycloneDX JSON |

`mixRelease` details:

- **Config:** `config.exs` and `config/<mixEnv>.exs` go into the compiled deps layer; `runtime.exs` and `releases.exs` only into the release. Config files imported outside that convention go in `extraConfig`.
- **Sources:** `lib`, `priv`, `src`, `rel`, `apps` and `assets` under `root`, those that exist, plus `extraSources`.
- **Dependencies:** Hex and git dependencies come from `mix.lock`.
- **Version:** `version` replaces `0.0.0+development` in every `mix.exs`.
- **Assets:** with an `assets.deploy` alias the release runs it with esbuild and tailwind from nixpkgs (tailwind 3 or 4 after the major version in `config/config.exs`); other Phoenix apps get `mix phx.digest`.
- **npm:** every `package-lock.json` at the root, in `assets/` or in `apps/*/assets/` gets its `node_modules` from the lockfile through nixpkgs `importNpmLock`.
- **Prebuilt NIFs:** exqlite, lazy_html, mdex_native and vix download a prebuilt NIF at compile time. The helper fetches the files for the build platform by the checksums each package ships and points `ELIXIR_MAKE_CACHE_DIR` and `RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH` at them. Other packages that do this cause a warning; add their GitHub repo in `lib/precompiled-nifs.nix`.
- **AppSignal:** the agent is fetched by the checksum in the package's `agent.exs` and unpacked into its `c_src`, which the package treats as a local agent release instead of downloading.
- **tzdata:** the release turns tzdata's autoupdate off unless the project's config sets it, because the Nix store is read-only; time zone data then comes with tzdata updates.
- **Release name:** umbrellas pass `release`.

## Test

```sh
devenv build outputs.root-deploy outputs.umbrella-subdir outputs.prod-runtime outputs.git-deps outputs.mix-assets outputs.mix-assets-tw3 outputs.npm-assets outputs.precompiled-nifs outputs.appsignal outputs.tzdata outputs.image outputs.sbom
```

Each fixture in `fixtures/` builds a release and runs its `check/0` inside it.
