class ChatMessage < ApplicationRecord
  belongs_to :user
  has_many :chat_reactions, dependent: :destroy
  has_many :mentions, dependent: :destroy

  enum :message_type, { regular: 0, system: 1, beacon: 2, campfire: 3 }

  validates :body, presence: true, length: { maximum: 300 }

  after_create_commit :broadcast_append
  after_create_commit :broadcast_notification
  after_commit :refresh_mentions, on: %i[ create update ]

  def mentioned_handles
    body.to_s.scan(/@([a-z0-9_]+)/i).flatten.map(&:downcase).uniq
  end

  private

  def broadcast_append
    broadcast_append_to "chat_messages",
                        target: "chat_messages",
                        partial: "chat_messages/chat_message",
                        locals: { chat_message: self }
  end

  def refresh_mentions
    mentions.delete_all
    handles = mentioned_handles
    return if handles.empty?

    User.where(handle: handles).find_each do |user|
      mentions.create!(user: user)
    end
  end

  def broadcast_notification
    ActionCable.server.broadcast(
      "chat_notifications",
      { source: "chat", user_id: user_id, message_id: id }
    )
  end
end
