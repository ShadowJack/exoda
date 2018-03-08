defmodule Exoda.MixProject do
  use Mix.Project

  def project do
    [
      app: :exoda,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  defp elixirc_paths(:test), do: ["lib", "test/fakes"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.2.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:httpoison, "~> 1.0.0"},
      {:jason, "~> 1.0"},
      {:sweet_xml, "~> 0.6.5"}
    ]
  end

  defp docs do
    [
      main: "Exoda",
      extras: ["README.md"]
    ]
  end
end
