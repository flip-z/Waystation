class CampfiresController < ApplicationController
  def show
    @room = CampfireRoom.includes(campfire_participants: :user).find(params[:id])
    CampfireRoom.close_stale!
    @room.reload
    @message = CampfireMessage.new
    @messages = @room.campfire_messages.includes(:user).order(created_at: :desc).limit(200).reverse
    @chat_users = User.all
  end

  def close
    room = CampfireRoom.find(params[:id])
    if room.created_by_id == current_user.id
      room.end!
      redirect_to chat_path, notice: "Campfire closed."
    else
      redirect_to chat_path, alert: "Not authorized."
    end
  end
end
