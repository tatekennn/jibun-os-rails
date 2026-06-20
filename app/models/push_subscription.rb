class PushSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh_key, presence: true
  validates :auth_key, presence: true

  scope :active, -> { where("failure_count < ?", 3) }

  def self.upsert_from_params!(subscription_params, user_agent: nil)
    data = subscription_params.with_indifferent_access
    keys = data.fetch(:keys)

    subscription = find_or_initialize_by(endpoint: data.fetch(:endpoint))
    subscription.assign_attributes(
      p256dh_key: keys.fetch(:p256dh),
      auth_key: keys.fetch(:auth),
      user_agent: user_agent,
      failed_at: nil,
      failure_count: 0
    )
    subscription.save!
    subscription
  end

  def mark_delivered!
    update!(last_success_at: Time.current, failed_at: nil)
  end

  def mark_failed!
    update!(failure_count: failure_count.to_i + 1, failed_at: Time.current)
  end
end
