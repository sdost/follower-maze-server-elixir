defmodule User.Server do
  require Logger

  @tcp_opts [:binary, packet: :line, active: false, reuseaddr: true, keepalive: true]

  def start(port) do
    { :ok, server } = :gen_tcp.listen(port, @tcp_opts)
    accept_client(server)
  end

  defp accept_client(server) do
    { :ok, client } = :gen_tcp.accept(server)
    spawn fn -> read_message(client) end
    accept_client(server)
  end

  defp read_message(client) do
    case :gen_tcp.recv(client, 0) do
      { :ok, message } ->
        message 
        |> String.trim
        |> String.to_integer
        |> register_user(client)
      { :error, _ } ->
        :gen_tcp.close(client)
    end
  end

  defp register_user(user_id, socket) do
    User.Manager.insert(user_id, socket)
  end
end