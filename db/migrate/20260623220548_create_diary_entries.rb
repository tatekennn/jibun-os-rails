class CreateDiaryEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :diary_entries do |t|
      t.date :wrote_on, null: false
      t.string :title
      t.string :mood, default: "normal", null: false
      t.string :weather
      t.text :body, null: false
      t.text :tags

      t.timestamps
    end

    add_index :diary_entries, :wrote_on, unique: true
    add_index :diary_entries, :mood
  end
end
