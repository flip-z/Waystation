class CampfireParticipant < ApplicationRecord
  belongs_to :campfire_room
  belongs_to :user

  validates :peer_id, presence: true, uniqueness: { scope: :campfire_room_id }
  validates :last_seen_at, presence: true
end
