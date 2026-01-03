class AddChatColorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :chat_color, :string, null: false, default: "phosphor_green"
    add_index :users, :chat_color
  end
end
