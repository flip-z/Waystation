class CreateCampfireParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :campfire_participants do |t|
      t.references :campfire_room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :peer_id, null: false
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    add_index :campfire_participants, [ :campfire_room_id, :peer_id ], unique: true
  end
end
