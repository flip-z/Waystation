class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_notifications"
  end
end
