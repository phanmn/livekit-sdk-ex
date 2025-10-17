defmodule LivekitSdkEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :livekit_sdk_ex,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:joken, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:inflex, "~> 2.1"},
      {:livekit_protocol_ex, git: "git@github.com:phanmn/livekit-protocol-ex.git", branch: "main"},
    ]
  end
end
