defmodule KousaTest.Broth.Room.MuteTest do
  use ExUnit.Case, async: true
  use KousaTest.Support.EctoSandbox

  alias Beef.Schemas.User
  alias Beef.Users
  alias BrothTest.WsClient
  alias BrothTest.WsClientFactory
  alias KousaTest.Support.Factory

  require WsClient

  setup do
    user = Factory.create(User)
    client_ws = WsClientFactory.create_client_for(user)

    {:ok, user: user, client_ws: client_ws}
  end

  describe "the websocket mute call operation" do
    test "can be used to mute", t do
      # first, create a room owned by the primary user.
      {:ok, %{room: %{id: room_id}}} = Kousa.Room.create_room(t.user.id, "foo room", "foo", false)
      # make sure the user is in there.
      assert %{currentRoomId: ^room_id} = Users.get_by_id(t.user.id)

      # mute ON
      ref = WsClient.send_call(t.client_ws, "room:mute", %{"muted" => true})
      WsClient.assert_reply("room:mute:reply", ref, _)
      map = Onion.RoomSession.get(room_id, :muteMap)
      assert is_map_key(map, t.user.id)

      # mute OFF
      ref = WsClient.send_call(t.client_ws, "room:mute", %{"muted" => false})
      WsClient.assert_reply("room:mute:reply", ref, _)
      map = Onion.RoomSession.get(room_id, :muteMap)
      Process.sleep(100)
      refute is_map_key(map, t.user.id)
    end

    test "can be used to unmute", t do
      # first, create a room owned by the primary user.
      {:ok, %{room: %{id: room_id}}} = Kousa.Room.create_room(t.user.id, "foo room", "foo", false)
      # make sure the user is in there.
      assert %{currentRoomId: ^room_id} = Users.get_by_id(t.user.id)

      ref = WsClient.send_call(t.client_ws, "room:mute", %{"muted" => false})

      WsClient.assert_reply("room:mute:reply", ref, _)

      map = Onion.RoomSession.get(room_id, :muteMap)

      assert map == %{}
    end
  end
end
