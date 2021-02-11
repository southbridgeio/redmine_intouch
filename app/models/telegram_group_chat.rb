class TelegramGroupChat < ActiveRecord::Base
  def self.find_by_tid(chat_id)
    return nil if chat_id.nil?
    # Telegram group id is always negative
    where("ABS(#{table_name}.tid) = ?", chat_id.abs).take
  end
end
