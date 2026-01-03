class SignupsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[ new create ]

  def new
    @invite = Invite.find_by(token: params[:token])
    unless @invite&.usable?
      redirect_to new_session_path, alert: "Invite invalid or expired."
      return
    end
    @user = User.new(email: @invite.email)
  end

  def create
    @invite = Invite.find_by(token: params[:token])
    unless @invite&.usable?
      redirect_to new_session_path, alert: "Invite invalid or expired."
      return
    end

    @user = User.new(email: @invite.email, role: @invite.role)

    if @user.save
      @invite.mark_used!
      reset_session
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
