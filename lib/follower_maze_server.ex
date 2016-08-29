defmodule FollowerMazeServer do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Event.Manager, []),
      worker(User.Manager, []),
      worker(Task, [Event.Server, :start, [9090]], [id: Event.Server]),
      worker(Task, [User.Server, :start, [9099]], [id: User.Server]),
    ]

    opts = [strategy: :one_for_one, name: FollowerMazeServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def main(_) do
    IO.gets "Press enter to stop servers."
  end
end
