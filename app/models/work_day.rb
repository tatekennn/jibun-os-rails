class WorkDay < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  scope :recent, -> { order(date: :desc) }

  def self.today
    find_or_create_by!(date: Date.current)
  end

  def confirm_check_in!
    update!(check_in_confirmed: true, check_in_confirmed_at: Time.current)
  end

  def confirm_check_out!
    update!(check_out_confirmed: true, check_out_confirmed_at: Time.current)
  end
end
