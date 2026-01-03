class User < ApplicationRecord
  enum :role, { member: 0, admin: 1 }
  enum :mic_mode, { push_to_talk: 0, open_mic: 1 }

  CHAT_COLORS = %w[
    phosphor_green
    amber_wave
    deep_cyan
    neon_blue
    soft_teal
    plasma_magenta
    hot_pink
    sunset_orange
    infra_red
    vintage_gold
    ghost_white
    lcd_violet
  ].freeze

  has_many :chat_messages, dependent: :destroy
  has_many :campfire_messages, dependent: :destroy
  has_many :chat_reactions, dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_many :campfire_rooms, foreign_key: :created_by_id, dependent: :nullify
  has_many :file_entries, foreign_key: :uploaded_by_id, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :handle, presence: true, uniqueness: { case_sensitive: false }
  validates :chat_color, inclusion: { in: CHAT_COLORS }

  before_validation :normalize_email
  before_validation :ensure_handle
  before_validation :normalize_handle
  before_validation :ensure_chat_color

  after_commit :broadcast_chat_colors, if: :saved_change_to_chat_color?

  def generate_magic_link!(expires_in: 30.minutes)
    update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current,
      magic_link_expires_at: Time.current + expires_in
    )
  end

  def magic_link_valid?(token)
    return false if magic_link_token.blank? || magic_link_expires_at.blank?
    return false unless token.is_a?(String) && token.bytesize == magic_link_token.bytesize

    ActiveSupport::SecurityUtils.secure_compare(magic_link_token, token) && magic_link_expires_at.future?
  end

  def clear_magic_link!
    update!(
      magic_link_token: nil,
      magic_link_sent_at: nil,
      magic_link_expires_at: nil
    )
  end

  def active_status?
    status_message.present? && status_expires_at&.future?
  end

  def can_read_files?
    admin? || files_read?
  end

  def can_upload_files?
    admin? || files_upload?
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def ensure_handle
    return if handle.present?

    base = email.to_s.split("@").first.to_s.downcase
    self.handle = base.presence || "user#{id || SecureRandom.random_number(9999)}"
  end

  def normalize_handle
    self.handle = handle.to_s.strip.downcase
  end

  def ensure_chat_color
    self.chat_color = chat_color.presence || "phosphor_green"
  end


  def broadcast_chat_colors
    users = User.where(id: ChatMessage.select(:user_id).distinct)
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_user_colors",
      target: "chat_user_colors",
      partial: "chat_messages/user_colors",
      locals: { users: users }
    )
  end
end
