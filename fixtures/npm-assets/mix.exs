defmodule FxNpm.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_npm,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [{:jason, "~> 1.4"}],
      aliases: ["assets.deploy": ["cmd --cd assets npm run deploy"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
