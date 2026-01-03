if Rails.env.production? || Rails.env.development?
  error_logger = Logger.new(Rails.root.join("log/errors.log"))
  error_logger.level = Logger::WARN

  ActiveSupport::Notifications.subscribe("process_action.action_controller") do |_name, _start, _finish, _id, payload|
    exception = payload[:exception_object]
    next unless exception

    error_logger.warn("[#{Time.current.iso8601}] #{exception.class}: #{exception.message}")
    error_logger.warn(exception.backtrace.join("\n")) if exception.backtrace
  end
end
