class DiaryEntry < ApplicationRecord
  MOODS = %w[good normal tired rough].freeze

  validates :wrote_on, :body, :mood, presence: true
  validates :wrote_on, uniqueness: true
  validates :mood, inclusion: { in: MOODS }

  scope :recent, -> { order(wrote_on: :desc, created_at: :desc) }

  def display_title
    title.presence || "#{wrote_on.strftime('%-m/%-d')}の日記"
  end

  def mood_label
    {
      "good" => "良い",
      "normal" => "普通",
      "tired" => "疲れ気味",
      "rough" => "しんどい"
    }.fetch(mood, mood)
  end
end
