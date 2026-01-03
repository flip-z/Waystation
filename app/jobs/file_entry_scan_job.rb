class FileEntryScanJob < ApplicationJob
  queue_as :default

  def perform(file_entry_id)
    file_entry = FileEntry.find_by(id: file_entry_id)
    return unless file_entry&.file&.attached?

    FileScanning::ClamavScanner.new(file_entry).scan!
  end
end
