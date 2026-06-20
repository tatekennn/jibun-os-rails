class CreateHobbyItems < ActiveRecord::Migration[7.2]
  def change
    create_table :hobby_items do |t|
      t.string :title, null: false
      t.string :category
      t.string :item_type, null: false, default: "memo"
      t.date :scheduled_on
      t.string :location
      t.integer :cost, null: false, default: 0
      t.string :url
      t.text :body
      t.integer :rating
      t.string :status, null: false, default: "planned"

      t.timestamps
    end

    add_index :hobby_items, :scheduled_on
    add_index :hobby_items, :item_type
    add_index :hobby_items, :status
  end
end
