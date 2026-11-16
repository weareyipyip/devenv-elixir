defmodule FxAppsignal.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_appsignal,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [{:appsignal, "~> 2.18"}]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
