require "test_helper"

class ChatFlowTest < ActionDispatch::IntegrationTest
  test "user can post a chat message" do
    user = User.create!(email: "chatter@example.com", role: :member)
    sign_in_as(user)

    assert_difference("ChatMessage.count", 1) do
      post chat_messages_path, params: { chat_message: { body: "Hello @chatter" } }
    end

    follow_redirect!
    assert_response :success
    assert_match "Hello @chatter", response.body
  end
end
