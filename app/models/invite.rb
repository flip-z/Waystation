class Invite < ApplicationRecord
  enum :role, { member: 0, admin: 1 }

  belongs_to :invited_by, class_name: "User"

  validates :email, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :normalize_email
  before_validation :set_defaults, on: :create

  def usable?
    used_at.nil? && expires_at.future?
  end

  def mark_used!
    update!(used_at: Time.current)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def set_defaults
    self.token = SecureRandom.urlsafe_base64(24) if token.blank?
    self.expires_at ||= 7.days.from_now
  end
end
