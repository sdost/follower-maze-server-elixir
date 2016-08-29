defmodule FollowerMazeServer.Mixfile do
  use Mix.Project

  def project do
    [app: :follower_maze_server,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: escript,
     deps: deps()]
  end

  def escript do
    [main_module: FollowerMazeServer]
  end

  def application do
    [applications: [:logger],
    mod: {FollowerMazeServer, []}]
  end

  defp deps do
    []
  end
end
