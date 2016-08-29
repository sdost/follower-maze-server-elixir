defmodule User.Manager do
  use GenServer
  require Logger

  defmodule State do
    defstruct sockets: %{}, follows: %{}
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def insert(user_id, socket) do
    :inet.setopts(socket, active: :once)
    GenServer.cast(__MODULE__, {:insert, user_id, socket})
  end

  def delete(user_id) do
    GenServer.cast(__MODULE__, {:delete, user_id})
  end

  def send_event(event) do
    command = 
      event 
      |> Map.from_struct 
      |> (fn %{type: type, from: from, to: to, msg: msg} -> {type, from, to, msg} end).()
    GenServer.cast(__MODULE__, command)
  end

  defp send_message(sockets, user_id, msg) do
    case Map.fetch(sockets, user_id) do
      {:ok, socket} ->
        :gen_tcp.send(socket, msg)
      :error -> :ok
    end
  end


  ## GenServer callbacks

  def init(_) do
    { :ok, %State{} }
  end

  def handle_info({:tcp_closed, socket}, state) do
    state.sockets
    |> Enum.find(fn {_, v} -> v == socket end)
    |> Enum.map(fn {_, v} -> v end)
    |> delete
  end

  def handle_cast({:follow, from, to, msg}, state) do
    send_message(state.sockets, to, msg)
    updated_follows =
      state.follows
      |> Map.get(to, MapSet.new)
      |> MapSet.put(from)
    { :noreply, %{state | follows: Map.put(state.follows, to, updated_follows)} }
  end

  def handle_cast({:unfollow, from, to, _}, state) do
    updated_follows =
      state.follows
      |> Map.get(to, MapSet.new)
      |> MapSet.delete(from)
    { :noreply, %{state | follows: Map.put(state.follows, to, updated_follows)} }
  end

  def handle_cast({:private, _, to, msg}, state) do
    send_message(state.sockets, to, msg)
    { :noreply, state }
  end

  def handle_cast({:status, from, _, msg}, state) do
    state.follows
    |> Map.get(from, MapSet.new)
    |> Enum.each(&send_message(state.sockets, &1, msg))
    { :noreply, state }
  end

  def handle_cast({:broadcast, _, _, msg}, state) do
    state.sockets
    |> Map.keys
    |> Enum.each(&send_message(state.sockets, &1, msg))
    { :noreply, state }
  end

  def handle_cast({:insert, user_id, socket}, state) do
    case Map.fetch(state.sockets, user_id) do
      {:ok, _socket} ->
        { :noreply, state }
      :error ->
        sockets = Map.put(state.sockets, user_id, socket)
        { :noreply, %{state | sockets: sockets} }
    end
  end

  def handle_cast({:delete, user_id}, state) do
    sockets = Map.delete(state.sockets, user_id)
    { :noreply, %{state | sockets: sockets} }
  end
end