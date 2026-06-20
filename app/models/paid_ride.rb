class PaidRide < ApplicationRecord
  validates :used_on, :line_name, presence: true
  validates :fare, numericality: { greater_than_or_equal_to: 0 }
  validates :fatigue_level, inclusion: { in: 1..5 }

  scope :recent, -> { order(used_on: :desc, created_at: :desc) }
  scope :this_month, -> {
    where(used_on: Date.current.beginning_of_month..Date.current.end_of_month)
  }

  def self.monthly_comment
    count = this_month.count

    if count >= 5
      "今月けっこう乗ってます。でも疲れているなら仕方ない。"
    elsif count <= 3
      "今月はまだ節制できてます。"
    else
      "ほどよく使って、体力を守れてます。"
    end
  end
end
