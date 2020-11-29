defmodule ExAtCoder.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_at_coder,
      version: "0.1.0",
      elixir: "~> 1.10",
      description: "mix task for Your AtCoder LIFE✨",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/tamanugi/ex_at_coder" }
      ]
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:httpoison, "~> 1.7"},
      {:floki, "~> 0.29.0"},
      {:yaml_elixir, "~> 2.5"}
    ]
  end
end
