class TelegramMessageSender
  include Sidekiq::Worker

  sidekiq_options queue: :telegram,
                  rate: {
                    name: 'telegram_rate_limit',
                    limit: 1,
                    period: 1
                  }

  def perform(telegram_account_id, message, params = {})
    RedmineBots::Telegram::Bot::MessageSender.call(chat_id: telegram_account_id, message: message, **params.transform_keys(&:to_sym))
  end
end
