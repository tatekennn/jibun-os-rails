class CreatePaidRides < ActiveRecord::Migration[7.2]
  def change
    create_table :paid_rides do |t|
      t.date :used_on, null: false
      t.string :line_name, null: false, default: "京王ライナー"
      t.string :direction
      t.integer :fare, null: false, default: 410
      t.string :reason
      t.integer :fatigue_level, null: false, default: 3
      t.text :memo

      t.timestamps
    end

    add_index :paid_rides, :used_on
  end
end
