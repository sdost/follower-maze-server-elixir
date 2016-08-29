defmodule Event.Manager do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def insert(%Event{} = event) do
    GenServer.cast(__MODULE__, {:insert, event})
  end

  def next(seq_id) do
    GenServer.call(__MODULE__, {:next, seq_id})
  end

  # GenServer callbacks

  def init(_) do
    { :ok, [] }
  end

  def handle_cast({:insert, event}, events) do
    {:noreply, Enum.sort_by([event | events], fn e -> e.seq_id end)}
  end

  def handle_call({:next, seq_id}, _from, events) do
    case events do
      [%Event{seq_id: ^seq_id} = event | tail] ->
        {:reply, {:ok, event}, tail}
      _ ->
        {:reply, {:error, :not_found}, events}
    end
  end
end