class AddChatSoundToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :chat_sound, :string, null: false, default: "beep"
    add_index :users, :chat_sound
  end
end
