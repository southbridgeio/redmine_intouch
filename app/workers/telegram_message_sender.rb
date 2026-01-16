class TelegramMessageSender
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :telegram

  sidekiq_throttle(
    threshold: { limit: 1, period: 1.second }
  )

  def perform(telegram_account_id, message, params = {})
    RedmineBots::Telegram.bot.send_message(chat_id: telegram_account_id, text: message, **params.transform_keys(&:to_sym))
  end
end
