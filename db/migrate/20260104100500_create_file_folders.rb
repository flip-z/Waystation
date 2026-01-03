class CreateFileFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :file_folders do |t|
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :file_folders }

      t.timestamps
    end

    add_index :file_folders, %i[parent_id name], unique: true
  end
end
