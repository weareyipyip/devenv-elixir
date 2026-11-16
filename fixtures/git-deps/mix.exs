defmodule FxGit.MixProject do
  use Mix.Project

  def project do
    [
      app: :fx_git,
      version: "0.0.0+development",
      elixir: "~> 1.18",
      deps: [
        {:jason, github: "michalmuskala/jason", tag: "v1.4.4"},
        {:heroicons,
         github: "tailwindlabs/heroicons",
         tag: "v2.2.0",
         sparse: "optimized",
         app: false,
         compile: false,
         depth: 1}
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
