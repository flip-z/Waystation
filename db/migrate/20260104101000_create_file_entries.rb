class CreateFileEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :file_entries do |t|
      t.references :folder, foreign_key: { to_table: :file_folders }
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.string :quarantine_reason
      t.datetime :scanned_at

      t.timestamps
    end

    add_index :file_entries, :status
  end
end
