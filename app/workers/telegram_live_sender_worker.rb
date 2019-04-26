class TelegramLiveSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, journal_id, recipient_ids)
    logger.debug "START for issue_id #{issue_id}"

    Intouch.set_locale

    issue = Intouch::IssueDecorator.new(Issue.find(issue_id), journal_id, protocol: 'telegram')
    logger.debug issue.inspect

    User.where(id: recipient_ids).each do |user|
      message = issue.as_markdown(user_id: user.id)
      
      logger.debug "user: #{user.inspect}"

      telegram_account = TelegramAccount.find_by(user_id: user.id)
      logger.debug "telegram_account: #{telegram_account.inspect}"
      next unless telegram_account.present?

      logger.debug message

      keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: [
              [
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: I18n.t('label_preview'),
                                                                 callback_data: { type: 'issue_preview', journal_id: journal_id }.to_json)
              ]
          ]
      )

      reply_markup = Intouch.telegram_preview? ? { reply_markup: keyboard } : {}
      RedmineBots::Telegram::Bot::MessageSender.call(message: message,
                                                     chat_id: telegram_account.telegram_id,
                                                     parse_mode: 'Markdown',
                                                     **reply_markup)
    end

    logger.debug "FINISH for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))
  end
end
