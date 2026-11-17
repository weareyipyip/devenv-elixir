defmodule FxNifs.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_nifs,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [{:mdex, "~> 0.11"}, {:vix, "~> 0.41"}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
