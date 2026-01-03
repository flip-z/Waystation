module Admin
  class InvitesController < BaseController
    def index
      @invites = Invite.order(created_at: :desc)
    end

    def new
      @invite = Invite.new
    end

    def create
      @invite = Invite.new(invite_params.merge(invited_by: current_user))

      if @invite.save
        redirect_to admin_invites_path, notice: "Invite created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def invite_params
      params.require(:invite).permit(:email, :role, :expires_at)
    end
  end
end
