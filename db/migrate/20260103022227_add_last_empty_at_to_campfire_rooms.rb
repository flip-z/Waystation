class AddLastEmptyAtToCampfireRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :campfire_rooms, :last_empty_at, :datetime
  end
end
