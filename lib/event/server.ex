defmodule Event do
  defstruct seq_id: nil, type: nil, from: nil, to: nil, msg: nil
end

defmodule Event.Server do
  require Logger

  @tcp_opts [:binary, packet: :line, active: false, reuseaddr: true]

  def start(port) do
    { :ok, server } = :gen_tcp.listen(port, @tcp_opts)
    accept_client(server)
  end

  defp accept_client(server) do
    { :ok, client } = :gen_tcp.accept(server)
    read_message(client, 1)
  end

  defp read_message(client, next_message) do
    case :gen_tcp.recv(client, 0) do
      { :ok, message } ->
        message 
        |> format_event
        |> parse_event 
        |> Event.Manager.insert
        read_message(client, process_event(next_message))
      { :error, _ } ->
        :gen_tcp.close(client)
    end
  end

  defp format_event(msg) do
    parsed_message = 
      msg
      |> String.split("|")
      |> Enum.map(&String.trim/1)
    {parsed_message, msg}
  end

  defp parse_event({[seq_id, "B"], msg}) do
    %Event{
      seq_id: String.to_integer(seq_id), 
      type: :broadcast,
      msg: msg
    }
  end

  defp parse_event({[seq_id, "S", from], msg}) do
    %Event{
      seq_id: String.to_integer(seq_id), 
      type: :status, 
      from: String.to_integer(from),
      msg: msg
    }
  end

  defp parse_event({[seq_id, "F", from, to], msg}) do
    %Event{
      seq_id: String.to_integer(seq_id), 
      type: :follow, 
      from: String.to_integer(from), 
      to: String.to_integer(to),
      msg: msg
    }
  end

  defp parse_event({[seq_id, "U", from, to], msg}) do
    %Event{
      seq_id: String.to_integer(seq_id), 
      type: :unfollow, 
      from: String.to_integer(from), 
      to: String.to_integer(to),
      msg: msg
    }
  end

  defp parse_event({[seq_id, "P", from, to], msg}) do
    %Event{
      seq_id: String.to_integer(seq_id), 
      type: :private, 
      from: String.to_integer(from), 
      to: String.to_integer(to),
      msg: msg
    }
  end

  defp process_event(seq_id) do
    case Event.Manager.next(seq_id) do
      { :ok, event } -> 
        User.Manager.send_event(event)
        process_event(seq_id + 1)
      { :error, _ } -> 
        seq_id
    end
  end
end