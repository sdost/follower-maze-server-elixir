defmodule User.Server do
  require Logger

  @tcp_opts [:binary, packet: :line, active: false, reuseaddr: true, keepalive: true]

  def start(port) do
    start_listener(port, 0)
  end

  defp start_listener(_, 3), do: Logger.debug("[User.Server] Failed to start listener.")
  defp start_listener(port, retry) do
    Logger.debug("[User.Server] Attempting to start listener. Retry: #{retry}")
    case :gen_tcp.listen(port, @tcp_opts) do
      {:ok, server} -> accept_client(server)
      {:error, _} -> start_listener(port, retry+1)
    end
  end

  defp accept_client(server) do
    case :gen_tcp.accept(server) do
      { :ok, client } -> spawn fn -> read_message(client) end
      _ -> Logger.error("[User.Server] Failed to accept new connection.")
    end
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