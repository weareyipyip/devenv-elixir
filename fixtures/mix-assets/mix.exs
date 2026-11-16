defmodule FxAssets.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_assets,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [
        {:phoenix, "~> 1.8"},
        {:jason, "~> 1.4"},
        {:esbuild, "~> 0.10", runtime: false},
        {:tailwind, "~> 0.4", runtime: false}
      ],
      aliases: [
        "assets.deploy": ["tailwind fx_assets --minify", "esbuild fx_assets --minify", "phx.digest"]
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
