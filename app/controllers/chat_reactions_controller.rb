class ChatReactionsController < ApplicationController
  def create
    message = ChatMessage.find(params[:chat_message_id])
    emoji = params[:emoji].to_s.strip
    if emoji.blank?
      redirect_to chat_path, alert: "Reaction cannot be blank."
      return
    end

    reaction = message.chat_reactions.find_or_initialize_by(user: current_user, emoji: emoji)
    reaction.save!

    redirect_to chat_path
  end

  def destroy
    message = ChatMessage.find(params[:chat_message_id])
    emoji = params[:emoji].to_s.strip
    reaction = message.chat_reactions.find_by!(user: current_user, emoji: emoji)
    reaction.destroy

    redirect_to chat_path
  end
end
