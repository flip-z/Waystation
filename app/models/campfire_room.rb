class CampfireRoom < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :campfire_messages, dependent: :destroy
  has_many :campfire_participants, dependent: :destroy

  scope :active, -> { where(active: true) }

  ACTIVE_LIMIT = 3

  def self.start_for!(user)
    existing = active.find_by(created_by: user)
    return existing if existing

    return nil if active.count >= ACTIVE_LIMIT

    room = create!(created_by: user, active: true, last_empty_at: Time.current, name: generate_name)
    broadcast_active_list
    room
  end

  def end!
    update!(active: false, ended_at: Time.current)
    campfire_participants.delete_all
    self.class.broadcast_active_list
    broadcast_campfire_badge
    update_campfire_announcement
  end

  def self.close_stale!(idle_for: 3.minutes)
    cutoff = idle_for.ago
    active.find_each do |room|
      stale_participants = room.campfire_participants.where("last_seen_at <= ?", cutoff)
      stale_participants.delete_all if stale_participants.exists?
      if room.campfire_participants.count.zero? && room.last_empty_at.nil?
        room.update!(last_empty_at: Time.current)
      end
    end
    active.where.not(last_empty_at: nil).where("last_empty_at <= ?", cutoff).find_each(&:end!)
  end

  def self.generate_name
    creatures = %w[
      Aboleth
      Ankheg
      Banshee
      Beholder
      Bulette
      Carrion_Crawler
      Chimera
      Chuul
      Cockatrice
      Doppelganger
      Drider
      Ettin
      Flumph
      Gauth
      Gelatinous_Cube
      Ghoul
      Giant_Spider
      Goblin
      Gorgon
      Grell
      Grick
      Harpy
      Hippogriff
      Hook_Horror
      Hydra
      Kenku
      Kuo_Toa
      Lich
      Mind_Flayer
      Mimic
      Minotaur
      Ochre_Jelly
      Ogre
      Owlbear
      Purple_Worm
      Roper
      Rust_Monster
      Sahuagin
      Shambling_Mound
      Stirge
      Troll
      Umber_Hulk
      Wyvern
    ]
    callsigns = %w[
      Alpha
      Bravo
      Charlie
      Delta
      Echo
      Foxtrot
      Golf
      Hotel
      India
      Juliet
      Kilo
      Lima
      Mike
      November
      Oscar
      Papa
      Quebec
      Romeo
      Sierra
      Tango
      Uniform
      Victor
      Whiskey
      Xray
      Yankee
      Zulu
    ]

    20.times do
      name = "#{creatures.sample.tr("_", " ")} #{callsigns.sample}"
      return name unless CampfireRoom.exists?(name: name)
    end

    "Campfire #{SecureRandom.hex(2)}"
  end

  def self.broadcast_active_list
    active_rooms = CampfireRoom.active.includes(:created_by).order(created_at: :desc)
    Turbo::StreamsChannel.broadcast_replace_to(
      "active_campfires",
      target: "active_campfires",
      partial: "chat_messages/active_campfires",
      locals: { active_campfires: active_rooms }
    )
  end

  def broadcast_campfire_badge
    announcement = ChatMessage.where(message_type: :campfire)
                              .where("metadata ->> 'room_id' = ?", id.to_s)
                              .order(created_at: :desc)
                              .first
    return unless announcement

    announcement.broadcast_replace_to(
      "chat_messages",
      target: ActionView::RecordIdentifier.dom_id(announcement),
      partial: "chat_messages/chat_message",
      locals: { chat_message: announcement }
    )
  end

  def update_campfire_announcement
    announcement = ChatMessage.where(message_type: :campfire)
                              .where("metadata ->> 'room_id' = ?", id.to_s)
                              .order(created_at: :desc)
                              .first
    return unless announcement

    duration = ActionController::Base.helpers.distance_of_time_in_words(created_at, Time.current)
    announcement.update!(
      body: "Campfire #{name} was closed after #{duration}."
    )
    announcement.broadcast_replace_to(
      "chat_messages",
      target: ActionView::RecordIdentifier.dom_id(announcement),
      partial: "chat_messages/chat_message",
      locals: { chat_message: announcement }
    )
  end
end
