class ChatMessagesController < ApplicationController
  def index
    @message = ChatMessage.new
    @messages = ChatMessage.includes(:user, :chat_reactions, :mentions).order(created_at: :desc).limit(200).reverse
    @active_statuses = User.where.not(status_message: nil).where("status_expires_at > ?", Time.current)
    @chat_users = User.where(id: ChatMessage.select(:user_id).distinct).or(User.where(id: current_user.id))
    @active_campfires = CampfireRoom.active.includes(:created_by).order(created_at: :desc)
    CampfireRoom.close_stale!
  end

  def create
    body = params.require(:chat_message).fetch(:body, "").to_s.strip
    if body.blank?
      respond_blank_message
      return
    end
    if body.start_with?("/")
      handle_command(body)
      respond_after_submit
      return
    end

    @message = current_user.chat_messages.build(body: body, message_type: :regular)
    if @message.save
      respond_after_submit
    else
      @messages = ChatMessage.includes(:user, :chat_reactions, :mentions).order(created_at: :desc).limit(200).reverse
      @active_statuses = User.where.not(status_message: nil).where("status_expires_at > ?", Time.current)
      respond_to do |format|
        format.html { render :index, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "chat_message_form",
            partial: "chat_messages/form",
            locals: { message: @message }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  private

  def handle_command(body)
    command, rest = body.split(" ", 2)
    case command
    when "/beacon"
      handle_beacon(rest.to_s)
    when "/campfire"
      handle_campfire
    else
      current_user.chat_messages.create!(body: "Unknown command: #{command}", message_type: :system)
    end
  end

  def handle_beacon(message)
    message = message.strip
    if message.blank? || message.casecmp("clear").zero?
      current_user.update!(status_message: nil, status_expires_at: nil)
      current_user.chat_messages.create!(body: "Beacon cleared.", message_type: :system)
      broadcast_beacons
      return
    end

    current_user.update!(status_message: message, status_expires_at: 24.hours.from_now)
    current_user.chat_messages.create!(body: message, message_type: :beacon)
    broadcast_beacons
  end

  def handle_campfire
    room = CampfireRoom.start_for!(current_user)
    unless room
      current_user.chat_messages.create!(body: "Campfire limit reached. Try later.", message_type: :system)
      return
    end

    existing = ChatMessage.where(message_type: :campfire)
      .where("metadata ->> 'room_id' = ?", room.id.to_s)
      .order(created_at: :desc)
      .first

    if existing
      current_user.chat_messages.create!(body: "Campfire already lit.", message_type: :system)
      return
    end

    current_user.chat_messages.create!(
      body: "Campfire #{room.name} is lit. Join the voice room.",
      message_type: :campfire,
      metadata: { room_id: room.id }
    )
  end

  def respond_blank_message
    respond_to do |format|
      format.html { redirect_to chat_path, alert: "Message cannot be blank." }
      format.turbo_stream do
        message = ChatMessage.new(body: "")
        message.errors.add(:body, "cannot be blank")
        render turbo_stream: turbo_stream.replace(
          "chat_message_form",
          partial: "chat_messages/form",
          locals: { message: message }
        ), status: :unprocessable_entity
      end
    end
  end

  def respond_after_submit
    respond_to do |format|
      format.html { redirect_to chat_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "chat_message_form",
          partial: "chat_messages/form",
          locals: { message: ChatMessage.new }
        )
      end
    end
  end

  def broadcast_beacons
    active_statuses = User.where.not(status_message: nil).where("status_expires_at > ?", Time.current)
    Turbo::StreamsChannel.broadcast_replace_to(
      "beacons",
      target: "beacons",
      partial: "chat_messages/beacons",
      locals: { active_statuses: active_statuses }
    )
  end
end
