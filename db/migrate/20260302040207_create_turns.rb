class CreateTurns < ActiveRecord::Migration[8.1]
  def change
    create_table :turns do |t|
      t.integer :turn_number, default: 1, null: false
      t.integer :p1_action
      t.integer :p2_action
      t.integer :status, default: 0, null: false
      t.integer :p1_hp_after
      t.integer :p2_hp_after
      t.integer :p1_energy_after
      t.integer :p2_energy_after
      t.references :match, null: false, foreign_key: true

      t.timestamps
    end
  end
end
