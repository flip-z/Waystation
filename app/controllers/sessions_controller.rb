class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[ new create ]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user
      user.generate_magic_link!
      MagicLinkMailer.with(user: user).login_link.deliver_now
      flash[:notice] = "Magic link sent. Check your email."
    else
      flash[:alert] = "Invite-only access. Ask an admin for an invite."
    end

    redirect_to new_session_path
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
