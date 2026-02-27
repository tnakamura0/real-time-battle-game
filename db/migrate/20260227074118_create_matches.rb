class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.integer :p1_hp, null: false
      t.integer :p2_hp, null: false
      t.integer :p1_energy, default: 0, null: false
      t.integer :p2_energy, default: 0, null: false
      t.integer :p1_last_guarded_turn
      t.integer :p2_last_guarded_turn
      t.integer :status, null: false
      t.references :room, null: true, foreign_key: { on_delete: :nullify }
      t.references :player_1, null: false, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :player_2, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end
  end
end
