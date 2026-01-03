class FileEntry < ApplicationRecord
  FILE_SIZE_LIMIT = -> { Rails.configuration.x.file_share.max_file_size }
  ALLOWED_CONTENT_TYPES = -> { Rails.configuration.x.file_share.allowed_content_types }

  belongs_to :folder, class_name: "FileFolder", optional: true
  belongs_to :uploaded_by, class_name: "User"

  has_one_attached :file

  enum :status, { pending: 0, clean: 1, quarantined: 2, error: 3, skipped: 4 }

  validates :file, presence: true
  validate :file_size_within_limit
  validate :file_content_type_allowed

  after_create_commit :enqueue_scan

  def downloadable?
    clean? || skipped?
  end

  def status_label
    case status
    when "pending"
      "Scanning"
    when "skipped"
      "Scan skipped"
    else
      status.titleize
    end
  end

  private

  def file_size_within_limit
    return unless file.attached?

    max_size = FILE_SIZE_LIMIT.call
    return if file.blob.byte_size <= max_size

    errors.add(:file, "exceeds the #{ActiveSupport::NumberHelper.number_to_human_size(max_size)} limit")
  end

  def file_content_type_allowed
    return unless file.attached?

    allowed = ALLOWED_CONTENT_TYPES.call
    return if allowed.blank? || allowed.include?(file.blob.content_type)

    errors.add(:file, "type is not allowed")
  end

  def enqueue_scan
    FileEntryScanJob.perform_later(id)
  end
end
