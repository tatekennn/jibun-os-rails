class LunchLog < ApplicationRecord
  validates :visited_on, :shop_name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :rating, inclusion: { in: 1..5 }

  scope :recent, -> { order(visited_on: :desc, created_at: :desc) }
  scope :this_month, -> {
    where(visited_on: Date.current.beginning_of_month..Date.current.end_of_month)
  }
  scope :recommended, -> { where(repeat: true).where("rating >= ?", 4).order(rating: :desc, price: :asc) }

  def stars
    "★" * rating
  end
end
