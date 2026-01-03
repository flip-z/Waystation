class CreateInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.string :token, null: false
      t.string :email, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.integer :role, null: false, default: 0
      t.references :invited_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :invites, :token, unique: true
  end
end
