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
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Описание', callback_data: "/preview_issue #{issue_id}"),
              ]
          ]
      )

      params = { reply_markup: keyboard }

      job = TelegramMessageSender.perform_async(telegram_account.telegram_id, message, params)

      logger.debug job.inspect
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
