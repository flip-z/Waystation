class MagicLinksController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    user = User.find_by(magic_link_token: params[:token])

    if user&.magic_link_valid?(params[:token])
      reset_session
      session[:user_id] = user.id
      user.update!(last_signed_in_at: Time.current)
      user.clear_magic_link!
      redirect_to root_path, notice: "Welcome back."
    else
      redirect_to new_session_path, alert: "Magic link expired or invalid."
    end
  end
end
