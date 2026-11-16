defmodule FxTw3.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_tw3,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [{:tailwind, "~> 0.4", runtime: false}],
      aliases: ["assets.deploy": ["tailwind fx_tw3 --minify"]]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
