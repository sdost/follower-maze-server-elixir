defmodule User.ServerTest do
  use ExUnit.Case, async: true

  require Event

  test "User listener starts and accepts connections" do
    assert {:ok, _} = :gen_tcp.connect('localhost', 9099, [:binary, active: :once])
  end

  test "User listener accept multiple connections" do
    assert {:ok, _} = :gen_tcp.connect('localhost', 9099, [:binary, active: :once])
    assert {:ok, _} = :gen_tcp.connect('localhost', 9099, [:binary, active: :once])
  end

  test "User connection registers user" do
    {:ok, socket} = :gen_tcp.connect('localhost', 9099, [:binary, active: :once])
    :gen_tcp.send(socket, '999\r\n')
    :inet.setopts(socket, active: :once)
    :timer.sleep(500) # Wait for registration to complete
    User.Manager.send_event(%Event{type: :broadcast, msg: '1|B\n'})
    assert_receive {:tcp, _, "1|B\n"} 
  end
end