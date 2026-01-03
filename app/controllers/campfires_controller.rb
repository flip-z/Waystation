class CampfiresController < ApplicationController
  def show
    @room = CampfireRoom.includes(campfire_participants: :user).find(params[:id])
    CampfireRoom.close_stale!
    @room.reload
    @message = CampfireMessage.new
    @messages = @room.campfire_messages.includes(:user).order(created_at: :desc).limit(200).reverse
    @chat_users = User.all
  end

  def voice_token
    room = CampfireRoom.find(params[:id])
    unless room.active?
      render json: { error: "Campfire closed." }, status: :gone
      return
    end

    livekit = CampfireLivekit.new(room: room, user: current_user)
    unless livekit.enabled?
      render json: { error: livekit.error_message || "LiveKit unavailable." }, status: :service_unavailable
      return
    end

    render json: { token: livekit.token, url: livekit.livekit_url, room: livekit.room_name }
  rescue StandardError => error
    Rails.logger.warn("LiveKit token error: #{error.class} #{error.message}")
    render json: { error: "LiveKit token error. Check server logs." }, status: :service_unavailable
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
