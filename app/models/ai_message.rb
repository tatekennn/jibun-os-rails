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
  scope :with_conversation_reply, -> { where.not(assistant_reply: [nil, ""]).or(where.not(error_message: [nil, ""])) }

  def self.recent_conversation(limit: 5, before: nil)
    relation = with_conversation_reply.recent
    if before&.persisted?
      relation = relation.where("created_at < ? OR (created_at = ? AND id < ?)", before.created_at, before.created_at, before.id)
    end

    relation.limit(limit).to_a.reverse
  end

  def conversation_reply
    assistant_reply.presence || error_message.presence
  end

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
