class TelegramGroupChat < ActiveRecord::Base
  def self.find_by_tid(chat_id)
    # Telegram group id is always negative
    where("ABS(#{table_name}.chat_id) = ?", chat_id.abs).take
  end
end
