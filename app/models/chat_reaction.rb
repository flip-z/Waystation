class ChatReaction < ApplicationRecord
  belongs_to :chat_message
  belongs_to :user

  validates :emoji, presence: true

  after_commit :broadcast_message

  private

  def broadcast_message
    chat_message.broadcast_replace_to(
      "chat_messages",
      partial: "chat_messages/chat_message",
      locals: { chat_message: chat_message }
    )
  end
end
