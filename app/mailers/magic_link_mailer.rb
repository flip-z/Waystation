class MagicLinkMailer < ApplicationMailer
  def login_link
    @user = params[:user]
    @url = magic_link_url(token: @user.magic_link_token)

    mail to: @user.email, subject: "Your Waystation login link"
  end
end
