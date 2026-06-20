class CreateLunchLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :lunch_logs do |t|
      t.date :visited_on, null: false
      t.string :shop_name, null: false
      t.string :area
      t.integer :price, null: false, default: 0
      t.integer :rating, null: false, default: 3
      t.string :crowdedness, null: false, default: "普通"
      t.boolean :solo_friendly, null: false, default: false
      t.boolean :repeat, null: false, default: false
      t.text :memo

      t.timestamps
    end

    add_index :lunch_logs, :visited_on
    add_index :lunch_logs, :rating
  end
end
