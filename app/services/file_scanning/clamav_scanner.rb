require "open3"

module FileScanning
  class ClamavScanner
    def initialize(file_entry)
      @file_entry = file_entry
    end

    def scan!
      return mark_skipped("ClamAV not available") unless clamav_available?

      file_entry.file.open do |file|
        stdout, status = Open3.capture2e(clamav_path, "--no-summary", file.path)

        case status.exitstatus
        when 0
          mark_clean
        when 1
          mark_quarantined("ClamAV flagged this file")
        else
          mark_error(stdout)
        end
      end
    rescue StandardError => e
      mark_error(e.message)
    end

    private

    attr_reader :file_entry

    def clamav_path
      ENV.fetch("CLAMSCAN_PATH", "clamscan")
    end

    def clamav_available?
      system(clamav_path, "-V", out: File::NULL, err: File::NULL)
    end

    def mark_clean
      file_entry.update!(status: :clean, scanned_at: Time.current, quarantine_reason: nil)
    end

    def mark_quarantined(reason)
      file_entry.update!(status: :quarantined, scanned_at: Time.current, quarantine_reason: reason)
    end

    def mark_error(reason)
      file_entry.update!(status: :error, scanned_at: Time.current, quarantine_reason: reason)
    end

    def mark_skipped(reason)
      file_entry.update!(status: :skipped, scanned_at: Time.current, quarantine_reason: reason)
    end
  end
end
