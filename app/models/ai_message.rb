require "securerandom"

class AiMessage < ApplicationRecord
  STATUSES = %w[pending delivered completed failed].freeze

  before_validation :ensure_public_id, :ensure_callback_token, on: :create

  validates :public_id, presence: true, uniqueness: true
  validates :callback_token, presence: true
  validates :body, presence: true
  validates :mode, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def mark_delivered!(message: nil)
    update!(status: "delivered", delivery_message: message.presence || delivery_message)
  end

  def complete!(reply:)
    update!(status: "completed", assistant_reply: reply.to_s.strip, completed_at: Time.current)
  end

  def fail!(message:)
    update!(status: "failed", error_message: message.to_s.strip.presence, completed_at: Time.current)
  end

  def finished?
    completed_at.present? || status.in?(%w[completed failed])
  end

  private

  def ensure_public_id
    self.public_id ||= SecureRandom.uuid
  end

  def ensure_callback_token
    self.callback_token ||= SecureRandom.urlsafe_base64(32)
  end
end
