require "test_helper"

class CampfiresControllerTest < ActionDispatch::IntegrationTest
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

  test "returns a livekit token for active campfires" do
    sign_in_as(@user)
    post voice_token_campfire_path(@room)

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal "https://livekit.example.com", data["url"]
    assert data["token"].present?
  end

  test "returns gone for closed campfires" do
    @room.update!(active: false)
    sign_in_as(@user)
    post voice_token_campfire_path(@room)

    assert_response :gone
  end
end
