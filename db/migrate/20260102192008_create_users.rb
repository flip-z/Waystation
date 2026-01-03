class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.integer :role, null: false, default: 0
      t.string :magic_link_token
      t.datetime :magic_link_sent_at
      t.datetime :magic_link_expires_at
      t.datetime :last_signed_in_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :magic_link_token, unique: true
  end
end
