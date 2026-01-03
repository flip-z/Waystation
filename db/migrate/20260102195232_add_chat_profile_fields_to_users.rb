class AddChatProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :handle, :string, null: false, default: ""
    add_column :users, :mic_mode, :integer, null: false, default: 0
    add_column :users, :status_message, :string
    add_column :users, :status_expires_at, :datetime

    User.reset_column_information
    User.find_each do |user|
      next if user.handle.present?

      handle = user.email.to_s.split("@").first.to_s.downcase
      handle = "user#{user.id}" if handle.blank?
      user.update_columns(handle: handle)
    end

    add_index :users, :handle, unique: true
    change_column_default :users, :handle, from: "", to: nil
  end

  def down
    remove_index :users, :handle
    remove_column :users, :status_expires_at
    remove_column :users, :status_message
    remove_column :users, :mic_mode
    remove_column :users, :handle
  end
end
