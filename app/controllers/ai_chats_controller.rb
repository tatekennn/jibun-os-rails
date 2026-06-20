class AiChatsController < ApplicationController
  def show
    @recent_ai_messages = AiMessage.recent_conversation(limit: 5)
  end
end
