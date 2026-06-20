class HobbyItem < ApplicationRecord
  ITEM_TYPES = %w[event memo].freeze
  STATUSES = %w[planned done archived].freeze

  validates :title, :item_type, :status, presence: true
  validates :item_type, inclusion: { in: ITEM_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true

  scope :recent, -> { order(Arel.sql("COALESCE(scheduled_on, created_at) DESC")) }
  scope :events, -> { where(item_type: "event") }
  scope :memos, -> { where(item_type: "memo") }
  scope :planned, -> { where(status: "planned") }

  def event?
    item_type == "event"
  end
end
