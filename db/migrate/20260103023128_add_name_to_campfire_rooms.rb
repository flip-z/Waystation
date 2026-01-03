class AddNameToCampfireRooms < ActiveRecord::Migration[8.1]
  def up
    add_column :campfire_rooms, :name, :string, null: false, default: ""

    CampfireRoom.reset_column_information
    CampfireRoom.find_each do |room|
      next if room.name.present?

      room.update_columns(name: generate_name)
    end

    add_index :campfire_rooms, :name, unique: true
    change_column_default :campfire_rooms, :name, from: "", to: nil
  end

  def down
    remove_index :campfire_rooms, :name
    remove_column :campfire_rooms, :name
  end

  private

  def generate_name
    creatures = %w[
      Centaur
      Griffin
      Phoenix
      Basilisk
      Kraken
      Dragon
      Gorgon
      Manticore
      Harpy
      Djinn
      Oni
      Kelpie
      Chimera
      Hydra
      Sphinx
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
      name = "#{creatures.sample} #{callsigns.sample}"
      return name unless CampfireRoom.exists?(name: name)
    end

    "Campfire #{SecureRandom.hex(2)}"
  end
end
