class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :token
      t.string :passcord
      t.integer :initial_hp
      t.integer :guard_cooldown_turns
      t.integer :status
      t.references :owner, null: false, foreign_key: true

      t.timestamps
    end
  end
end
