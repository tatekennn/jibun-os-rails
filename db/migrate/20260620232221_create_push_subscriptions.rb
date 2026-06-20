class CreatePushSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :push_subscriptions do |t|
      t.text :endpoint, null: false
      t.text :p256dh_key, null: false
      t.text :auth_key, null: false
      t.string :user_agent
      t.integer :failure_count, null: false, default: 0
      t.datetime :last_success_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end
