class CreateCampfireRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :campfire_rooms do |t|
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.boolean :active, null: false, default: true
      t.datetime :ended_at

      t.timestamps
    end

    add_index :campfire_rooms, :active
  end
end
