Rails.application.config.x.file_share.max_file_size = ENV.fetch("FILE_SHARE_MAX_SIZE_MB", "2").to_i.megabytes
Rails.application.config.x.file_share.allowed_content_types = begin
  env_types = ENV["FILE_SHARE_ALLOWED_TYPES"]
  if env_types.present?
    env_types.split(",").map(&:strip)
  else
    %w[
      application/pdf
      application/msword
      application/vnd.ms-excel
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      application/zip
      application/x-7z-compressed
      application/x-tar
      application/gzip
      text/plain
      text/markdown
      image/jpeg
      image/png
      image/gif
      image/webp
      audio/mpeg
      audio/ogg
      audio/wav
      audio/x-wav
      audio/mp4
    ]
  end
end
