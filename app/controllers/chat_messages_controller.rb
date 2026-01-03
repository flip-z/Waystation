class ChatMessagesController < ApplicationController
  helper_method :timeframe_label

  def index
    @tab = normalized_tab(params[:tab])
    @timeframe = normalized_timeframe(params[:timeframe])

    CampfireRoom.close_stale!

    if dashboard_tab?
      load_dashboard_stats
    else
      load_chat_content
    end
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
      @tab = "chat"
      @timeframe = normalized_timeframe(params[:timeframe])
      @messages = ChatMessage.includes(:user, :chat_reactions, :mentions).order(created_at: :desc).limit(200).reverse
      @active_statuses = active_beacons
      @chat_users = User.where(id: ChatMessage.select(:user_id).distinct).or(User.where(id: current_user.id))
      @active_campfires = CampfireRoom.active.includes(:created_by).order(created_at: :desc)
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

  def normalized_timeframe(value)
    value.presence_in(%w[day week month year all]) || "week"
  end

  def normalized_tab(value)
    value.presence_in(%w[chat dashboard]) || "chat"
  end

  def dashboard_tab?
    @tab == "dashboard"
  end

  def timeframe_label
    {
      "day" => "Last Day",
      "week" => "Last Week",
      "month" => "Last Month",
      "year" => "Last Year",
      "all" => "All Time"
    }.fetch(@timeframe, "Last Week")
  end

  def timeframe_range
    case @timeframe
    when "day" then 1.day.ago..Time.current
    when "week" then 1.week.ago..Time.current
    when "month" then 1.month.ago..Time.current
    when "year" then 1.year.ago..Time.current
    else
      nil
    end
  end

  def load_chat_content
    @message = ChatMessage.new
    @messages = ChatMessage.includes(:user, :chat_reactions, :mentions).order(created_at: :desc).limit(200).reverse
    @active_statuses = active_beacons
    @chat_users = User.where(id: ChatMessage.select(:user_id).distinct).or(User.where(id: current_user.id))
    @active_campfires = CampfireRoom.active.includes(:created_by).order(created_at: :desc)
  end

  def load_dashboard_stats
    time_range = timeframe_range
    @message_counts = grouped_counts(ChatMessage.where(message_type: :regular), :user_id, time_range)
    @campfire_counts = grouped_counts(CampfireRoom.all, :created_by_id, time_range)
  end

  def grouped_counts(scope, group_key, time_range)
    scoped = time_range ? scope.where(created_at: time_range) : scope
    counts = scoped.group(group_key).order(Arel.sql("COUNT(*) DESC")).limit(10).count
    users = User.where(id: counts.keys).index_by(&:id)

    counts.map do |id, total|
      user = users[id]
      next unless user

      [user, total]
    end.compact
  end

  def active_beacons
    User.where.not(status_message: nil).where("status_expires_at > ?", Time.current)
  end

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
