class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :token, null: false
      t.string :passcord, null: false
      t.integer :initial_hp, default: 3, null: false
      t.integer :guard_cooldown_turns, default: 1, null: false
      t.integer :status, default: 0, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps

      t.index :token
      t.index :passcord
    end
  end
end
