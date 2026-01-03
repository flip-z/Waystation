require "test_helper"

class InviteFlowTest < ActionDispatch::IntegrationTest
  test "invite can be accepted to create a user" do
    admin = User.create!(email: "admin@example.com", role: :admin)
    invite = Invite.create!(email: "newcomer@example.com", role: :member, invited_by: admin)

    get new_signup_path(token: invite.token)
    assert_response :success

    assert_difference("User.count", 1) do
      post signups_path(token: invite.token)
    end

    invite.reload
    assert invite.used_at.present?
  end
end
