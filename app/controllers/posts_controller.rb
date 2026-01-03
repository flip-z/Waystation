class PostsController < ApplicationController
  def index
    @posts = Post.visible.recent_first
  end

  def show
    @post = if current_user&.admin?
      Post.find_by!(slug: params[:id])
    else
      Post.visible.find_by!(slug: params[:id])
    end
    @history = @post.history_entries
    @version = params[:version]
    @body = @post.body_at_revision(@version)

    increment_view_count if @post.published?
  end

  private

  def increment_view_count
    Post.increment_counter(:view_count, @post.id)
  end
end
