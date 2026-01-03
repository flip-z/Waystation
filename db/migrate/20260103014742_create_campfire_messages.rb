class CreateCampfireMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :campfire_messages do |t|
      t.references :campfire_room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :campfire_messages, :created_at
  end
end
