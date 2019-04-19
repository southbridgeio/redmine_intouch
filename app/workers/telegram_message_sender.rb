class TelegramMessageSender
  include Sidekiq::Worker
  sidekiq_options queue: :telegram,
                  rate: {
                    name: 'telegram_rate_limit',
                    limit: 15,
                    period: 1
                  }

  TELEGRAM_MESSAGE_SENDER_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-message-sender.log'))
  TELEGRAM_MESSAGE_SENDER_ERRORS_LOG = Logger.new(Rails.root.join('log/intouch', 'telegram-message-sender-errors.log'))

  def perform(telegram_account_id, message, params = {})
    token = Intouch.bot_token
    bot = Telegram::Bot::Client.new(token)

    begin
      bot.api.send_message(chat_id: telegram_account_id,
                           text: message,
                           disable_web_page_preview: true,
                           parse_mode: 'Markdown',
                           **params)
      TELEGRAM_MESSAGE_SENDER_LOG.info "telegram_account_id: #{telegram_account_id}\tmessage: #{message}"

    rescue => e

      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.info "MESSAGE: #{message}"

      telegram_account = (telegram_account_id > 0) ?
        TelegramAccount.find_by(telegram_id: telegram_account_id) :
        TelegramGroupChat.find_by(tid: telegram_account_id.abs)

      if e.message.include? 'Bot was kicked'
        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.info "Bot was kicked from chat."

      elsif e.message.include?('429') || e.message.include?('retry later')

        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "429 retry later error. retry to send after 5 seconds\ntelegram_account_id: #{telegram_account_id}\tmessage: #{message}"
        TelegramMessageSender.perform_in(5.seconds, telegram_account_id, message)

      else

        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "#{e.class}: #{e.message}"
        TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.debug "#{telegram_account.inspect}"

      end

    end
  end
end
