require "test_helper"

class CampfireLivekitTest < ActiveSupport::TestCase
  setup do
    @original_env = ENV.to_hash
    ENV["LIVEKIT_API_KEY"] = "test_key"
    ENV["LIVEKIT_API_SECRET"] = "test_secret"
    ENV["LIVEKIT_URL"] = "https://livekit.example.com"
    @user = users(:one)
    @room = CampfireRoom.create!(
      created_by: @user,
      active: true,
      name: CampfireRoom.generate_name
    )
  end

  teardown do
    ENV.replace(@original_env) if @original_env
  end

  test "builds a livekit token scoped to the campfire room" do
    livekit = CampfireLivekit.new(room: @room, user: @user)
    token = livekit.token

    verifier = LiveKit::TokenVerifier.new(
      api_key: ENV["LIVEKIT_API_KEY"],
      api_secret: ENV["LIVEKIT_API_SECRET"]
    )
    claims = verifier.verify(token)

    assert_equal @user.id.to_s, claims.identity
    assert_equal @user.handle, claims.name
    assert_equal livekit.room_name, claims.video.room
    assert claims.video.roomJoin
  end
end
