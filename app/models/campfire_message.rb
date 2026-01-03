class CampfireMessage < ApplicationRecord
  belongs_to :campfire_room
  belongs_to :user

  validates :body, presence: true, length: { maximum: 300 }

  after_create_commit :broadcast_append
  after_create_commit :broadcast_notification

  private

  def broadcast_append
    broadcast_append_to [campfire_room, :campfire_messages],
                        target: "campfire_messages",
                        partial: "campfire_messages/message",
                        locals: { message: self }

    # message count now calculated directly in views
  end

  def broadcast_notification
    ActionCable.server.broadcast(
      "chat_notifications",
      {
        source: "campfire",
        user_id: user_id,
        message_id: id,
        campfire_room_id: campfire_room_id
      }
    )
  end
end
