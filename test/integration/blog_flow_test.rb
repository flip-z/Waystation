require "test_helper"

class BlogFlowTest < ActionDispatch::IntegrationTest
  test "published posts appear on the blog index and show page" do
    user = User.create!(email: "author@example.com", role: :admin)
    post = Post.create!(
      title: "First signal",
      slug: "first-signal",
      body_markdown: "Hello from the waypoint.",
      status: :published,
      published_at: 1.hour.ago
    )

    sign_in_as(user)
    get posts_path
    assert_response :success
    assert_match post.title, response.body

    get post_path(post)
    assert_response :success
    assert_match "Hello from the waypoint.", response.body
  end
end
