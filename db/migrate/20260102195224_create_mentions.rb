class CreateMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :mentions do |t|
      t.references :chat_message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :mentions, [ :chat_message_id, :user_id ], unique: true
  end
end
