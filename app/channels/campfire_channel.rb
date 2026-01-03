class CampfireChannel < ApplicationCable::Channel
  def subscribed
    @room_id = params[:room_id].to_s
    @peer_id = params[:peer_id].to_s
    if @room_id.blank?
      Rails.logger.info("[CampfireChannel] Rejecting: missing room_id")
      reject
      return
    end
    if @peer_id.blank?
      Rails.logger.info("[CampfireChannel] Rejecting: missing peer_id")
      reject
      return
    end

    CampfireRoom.close_stale!
    room = CampfireRoom.find_by(id: @room_id, active: true)
    unless room
      Rails.logger.info("[CampfireChannel] Rejecting: room #{@room_id} not active")
      reject
      return
    end

    stream_from stream_name

    if room.campfire_participants.count >= 10 && room.campfire_participants.where(peer_id: @peer_id).none?
      Rails.logger.info("[CampfireChannel] Rejecting: room #{@room_id} at capacity")
      reject
      return
    end

    participant = room.campfire_participants.find_or_initialize_by(peer_id: @peer_id)
    participant.user = current_user
    participant.last_seen_at = Time.current
    participant.save!
    room.update!(last_empty_at: nil)

    participants = room.campfire_participants.includes(:user).map do |member|
      { peer_id: member.peer_id, user_id: member.user_id, handle: member.user.handle }
    end
    transmit({ type: "participants", participants: participants })
    ActionCable.server.broadcast(
      stream_name,
      { type: "join", participant: { peer_id: @peer_id, user_id: current_user.id, handle: current_user.handle } }
    )
    Rails.logger.info("[CampfireChannel] Subscribed peer #{@peer_id} to room #{@room_id}")
  end

  def unsubscribed
    room = CampfireRoom.find_by(id: @room_id)
    return unless room

    room.campfire_participants.where(peer_id: @peer_id).delete_all
    room.update!(last_empty_at: Time.current) if room.campfire_participants.count.zero?
    ActionCable.server.broadcast(
      stream_name,
      { type: "leave", participant: { peer_id: @peer_id, user_id: current_user.id, handle: current_user.handle } }
    )
    Rails.logger.info("[CampfireChannel] Unsubscribed peer #{@peer_id} from room #{@room_id}")
  end

  def signal(data)
    ActionCable.server.broadcast(
      stream_name,
      {
        type: "signal",
        target_id: data["target_id"],
        sender_id: @peer_id,
        signal: data["signal"]
      }
    )
  end

  def presence_ping
    room = CampfireRoom.find_by(id: @room_id)
    return unless room

    participant = room.campfire_participants.find_by(peer_id: @peer_id)
    return unless participant

    participant.update!(last_seen_at: Time.current)
  end

  private

  def stream_name
    "campfire_room_#{@room_id}"
  end

end
