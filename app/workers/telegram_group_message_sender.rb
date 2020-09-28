class TelegramGroupMessageSender
  include Sidekiq::Worker

  sidekiq_options queue: :telegram,
                  rate: {
                    name: 'telegram_group_rate_limit',
                    limit: 20,
                    period: 60
                  }

  def perform(chat_id, message, issue_id, journal_id)
    chat = TelegramGroupChat.find_by(id: chat_id) || return

    Intouch.handle_group_upgrade(chat) do |group|
      next unless group.tid.present?

      bot.send_message(text: message,
                       chat_id: -group.tid,
                       parse_mode: 'HTML',
                       **Intouch::Preview::KeyboardMarkup.build_hash(issue_id, journal_id))
    end
  end

  private

  def bot
    RedmineBots::Telegram.bot
  end
end
