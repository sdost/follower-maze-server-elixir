defmodule Event.ServerTest do
  use ExUnit.Case, async: true

  require Event

  test "Event listener starts and accepts connections" do
    assert {:ok, _} = :gen_tcp.connect('localhost', 9090, [:binary, active: false])
  end
end