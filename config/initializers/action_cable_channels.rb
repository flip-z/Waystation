# Ensure ActionCable channels are loaded so subscriptions can constantize.
Rails.application.config.to_prepare do
  Dir[Rails.root.join("app/channels/**/*_channel.rb")].sort.each do |path|
    require path
  end
  Rails.logger.info("[ActionCable] Channel files loaded.")
end
