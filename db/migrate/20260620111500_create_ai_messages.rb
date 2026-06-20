class CreateAiMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_messages do |t|
      t.string :public_id, null: false
      t.string :callback_token, null: false
      t.text :body, null: false
      t.string :mode, null: false, default: "dashboard"
      t.text :context
      t.string :status, null: false, default: "pending"
      t.text :assistant_reply
      t.text :delivery_message
      t.text :error_message
      t.datetime :completed_at

      t.timestamps
    end

    add_index :ai_messages, :public_id, unique: true
    add_index :ai_messages, :status
    add_index :ai_messages, :created_at
  end
end
