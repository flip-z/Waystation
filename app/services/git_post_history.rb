require "open3"

class GitPostHistory
  def self.log_for(path)
    return [] unless available?(path)

    output, status = Open3.capture2(
      "git",
      "log",
      "--pretty=format:%h|%ad|%s",
      "--date=iso",
      "--",
      path,
      chdir: Rails.root.to_s
    )

    return [] unless status.success?

    output.lines.filter_map do |line|
      sha, date, subject = line.strip.split("|", 3)
      next if sha.blank?

      { sha: sha, date: date, subject: subject }
    end
  end

  def self.read_file_at_revision(path, revision)
    return nil unless available?(path)

    output, status = Open3.capture2(
      "git",
      "show",
      "#{revision}:#{path}",
      chdir: Rails.root.to_s
    )

    status.success? ? output : nil
  end

  def self.available?(path)
    return false unless File.exist?(Rails.root.join(path))

    _, status = Open3.capture2e("git", "rev-parse", "--is-inside-work-tree", chdir: Rails.root.to_s)
    return false unless status.success?

    _, head_status = Open3.capture2e("git", "rev-parse", "--verify", "HEAD", chdir: Rails.root.to_s)
    head_status.success?
  end
end
