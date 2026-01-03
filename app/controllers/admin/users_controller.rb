module Admin
  class UsersController < BaseController
    before_action :set_user, only: :update

    def index
      @users = User.order(:handle)
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User permissions updated."
      else
        redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:files_read, :files_upload)
    end
  end
end
