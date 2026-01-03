require "test_helper"

class CampfireChannelTest < ActionCable::Channel::TestCase
  setup do
    @user = users(:one)
    @room = CampfireRoom.create!(created_by: @user, active: true)
    CampfirePresence.clear(@room.id)
  end

  test "broadcasts presence on subscribe and unsubscribe" do
    stub_connection current_user: @user

    assert_broadcasts("campfire_presence", 1) do
      subscribe(room_id: @room.id, peer_id: "peer-1")
      assert subscription.confirmed?
    end
    assert_includes broadcasts("campfire_presence").last, "campfire_presence_#{@room.id}"
    assert_equal "participants", transmissions.last["type"]
    assert_includes transmissions.last["peers"], "peer-1"

    assert_broadcasts("campfire_presence", 1) do
      unsubscribe
    end
    assert_includes broadcasts("campfire_presence").last, "campfire_presence_#{@room.id}"
  end

  test "rejects when room is closed" do
    @room.update!(active: false)
    stub_connection current_user: @user
    subscribe(room_id: @room.id, peer_id: "peer-2")
    assert subscription.rejected?
  end
end
