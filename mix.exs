defmodule Exoda.MixProject do
  use Mix.Project

  def project do
    [
      app: :exoda,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "Exoda",
      source_url: "https://github.com/ShadowJack/exoda",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.2.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:httpoison, "~> 1.0.0"}
    ]
  end

  defp docs do
    [
      main: "Exoda",
      extras: ["README.md"]
    ]
  end
end
