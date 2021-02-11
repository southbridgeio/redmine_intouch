class Intouch::TelegramChatSubscription < ActiveRecord::Base
  belongs_to :issue

  validates_presence_of :issue_id, :chat_id

  def self.table_name
    'intouch_telegram_chat_subscriptions'
  end

  def self.find_by_chat_id(chat_id)
    # Telegram group id is always negative
    where("ABS(#{table_name}.chat_id) = ?", chat_id.abs).take
  end
end
