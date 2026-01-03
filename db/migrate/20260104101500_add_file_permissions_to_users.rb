class AddFilePermissionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :files_read, :boolean, null: false, default: true
    add_column :users, :files_upload, :boolean, null: false, default: false
  end
end
