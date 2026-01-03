module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[ edit update destroy ]

    def index
      @posts = Post.order(updated_at: :desc)
    end

    def new
      @post = Post.new
    end

    def create
      @post = Post.new(post_params)
      assign_tags

      if @post.save
        redirect_to admin_posts_path, notice: "Post created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @post.assign_attributes(post_params)
      assign_tags

      if @post.save
        redirect_to admin_posts_path, notice: "Post updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Post deleted."
    end

    private

    def set_post
      @post = Post.find_by!(slug: params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :slug, :body_markdown, :status, :published_at)
    end

    def assign_tags
      tag_list = params[:post].fetch(:tag_list, nil)
      return if tag_list.nil?

      tag_names = tag_list.split(",").map { |name| name.strip.downcase }.reject(&:blank?)
      @post.tags = tag_names.map { |name| Tag.find_or_create_by!(name: name) }
    end
  end
end
