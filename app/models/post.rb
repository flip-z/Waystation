require "fileutils"

class Post < ApplicationRecord
  CONTENT_ROOT = Rails.root.join("content/posts")

  enum :status, { draft: 0, scheduled: 1, published: 2 }

  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :title, :body_markdown, :slug, presence: true
  validates :slug, uniqueness: true
  validate :scheduled_requires_published_at

  before_validation :set_slug
  before_save :store_previous_slug, if: :will_save_change_to_slug?
  before_save :set_published_at, if: :published?
  after_commit :write_content_file, on: %i[ create update ]
  after_destroy :remove_content_file

  scope :visible, -> { where(status: %i[ published scheduled ]).where("published_at IS NULL OR published_at <= ?", Time.current) }
  scope :recent_first, -> { order(published_at: :desc, created_at: :desc) }

  def to_param
    slug
  end

  def content_path
    CONTENT_ROOT.join("#{slug}.md")
  end

  def content_path_relative
    content_path.relative_path_from(Rails.root).to_s
  end

  def body_at_revision(revision)
    return body_markdown if revision.blank?

    GitPostHistory.read_file_at_revision(content_path_relative, revision) || body_markdown
  end

  def history_entries
    GitPostHistory.log_for(content_path_relative)
  end

  private

  def set_slug
    base = title.to_s.parameterize
    self.slug = base if slug.blank?
  end

  def set_published_at
    self.published_at ||= Time.current
  end

  def scheduled_requires_published_at
    return unless scheduled? && published_at.blank?

    errors.add(:published_at, "is required for scheduled posts")
  end

  def write_content_file
    FileUtils.mkdir_p(CONTENT_ROOT)
    File.write(content_path, body_markdown)

    return if @previous_slug.blank? || @previous_slug == slug

    old_path = CONTENT_ROOT.join("#{@previous_slug}.md")
    File.delete(old_path) if File.exist?(old_path)
  end

  def remove_content_file
    File.delete(content_path) if File.exist?(content_path)
  end

  def store_previous_slug
    @previous_slug = slug_was
  end
end
