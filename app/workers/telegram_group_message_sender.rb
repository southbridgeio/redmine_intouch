class TelegramGroupMessageSender
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :telegram

  sidekiq_throttle(
    threshold: { limit: 20, period: 60.seconds }
  )

  def perform(chat_id, message, issue_id, journal_id)
    chat = TelegramGroupChat.find_by(id: chat_id) || return

    Intouch.handle_group_upgrade(chat) do |group|
      next unless group.tid.present?

      bot.send_message(text: message,
                       chat_id: -group.tid.abs,
                       parse_mode: 'HTML',
                       **Intouch::Preview::KeyboardMarkup.build_hash(issue_id, journal_id))
    end
  end

  private

  def bot
    RedmineBots::Telegram.bot
  end
end
