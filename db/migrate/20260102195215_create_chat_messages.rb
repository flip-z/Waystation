class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.integer :message_type, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :chat_messages, :message_type
    add_index :chat_messages, :created_at
  end
end
