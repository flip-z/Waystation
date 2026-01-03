class CampfireLivekit
  ROOM_PREFIX = "campfire".freeze

  def initialize(room:, user:)
    @room = room
    @user = user
    @load_error = nil
    @livekit_loaded = false
    ensure_livekit_loaded
  end

  def enabled?
    @load_error.nil? && livekit_url.present? && api_key.present? && api_secret.present?
  end

  def error_message
    return @load_error if @load_error

    missing = []
    missing << "LIVEKIT_URL" if livekit_url.blank?
    missing << "LIVEKIT_API_KEY" if api_key.blank?
    missing << "LIVEKIT_API_SECRET" if api_secret.blank?
    return "Missing LiveKit config: #{missing.join(', ')}" if missing.any?

    nil
  end

  def room_name
    "#{ROOM_PREFIX}-#{@room.id}"
  end

  def token
    ensure_livekit_loaded
    raise @load_error if @load_error
    raise "LiveKit not configured" unless enabled?

    access_token = LiveKit::AccessToken.new(
      api_key: api_key,
      api_secret: api_secret,
      identity: @user.id.to_s,
      name: @user.handle,
      ttl: 60 * 60
    )
    access_token.video_grant = LiveKit::VideoGrant.new(
      roomJoin: true,
      room: room_name,
      canPublish: true,
      canSubscribe: true,
      canPublishData: false
    )
    access_token.to_jwt
  end

  def livekit_url
    ENV["LIVEKIT_URL"].to_s
  end

  private

  def api_key
    ENV["LIVEKIT_API_KEY"].to_s
  end

  def api_secret
    ENV["LIVEKIT_API_SECRET"].to_s
  end

  def ensure_livekit_loaded
    return if @livekit_loaded

    require "livekit"
    @livekit_loaded = true
  rescue LoadError => error
    @load_error = "LiveKit gem not available. Run `bundle install`."
  end
end
