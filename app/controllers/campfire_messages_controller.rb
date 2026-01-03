class CampfireMessagesController < ApplicationController
  def create
    @room = CampfireRoom.find(params[:campfire_id])
    CampfireRoom.close_stale!
    unless @room.active?
      redirect_to chat_path, alert: "Campfire is closed."
      return
    end

    body = params.require(:campfire_message).fetch(:body, "").to_s.strip
    if body.blank?
      respond_blank_message
      return
    end

    @message = @room.campfire_messages.build(user: current_user, body: body)
    if @message.save
      respond_after_submit
    else
      respond_invalid
    end
  end

  private

  def respond_blank_message
    respond_to do |format|
      format.html { redirect_to campfire_path(@room), alert: "Message cannot be blank." }
      format.turbo_stream do
        message = CampfireMessage.new(body: "")
        message.errors.add(:body, "cannot be blank")
        render turbo_stream: turbo_stream.replace(
          "campfire_message_form",
          partial: "campfire_messages/form",
          locals: { room: @room, message: message }
        ), status: :unprocessable_entity
      end
    end
  end

  def respond_after_submit
    respond_to do |format|
      format.html { redirect_to campfire_path(@room) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "campfire_message_form",
          partial: "campfire_messages/form",
          locals: { room: @room, message: CampfireMessage.new }
        )
      end
    end
  end

  def respond_invalid
    respond_to do |format|
      format.html { redirect_to campfire_path(@room), alert: "Message invalid." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "campfire_message_form",
          partial: "campfire_messages/form",
          locals: { room: @room, message: @message }
        ), status: :unprocessable_entity
      end
    end
  end
end
