class CreateWorkDays < ActiveRecord::Migration[7.2]
  def change
    create_table :work_days do |t|
      t.date :date, null: false
      t.boolean :check_in_confirmed, null: false, default: false
      t.boolean :check_out_confirmed, null: false, default: false
      t.datetime :check_in_confirmed_at
      t.datetime :check_out_confirmed_at
      t.text :memo

      t.timestamps
    end

    add_index :work_days, :date, unique: true
  end
end
