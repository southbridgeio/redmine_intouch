class TelegramLiveSenderWorker
  include Sidekiq::Worker

  sidekiq_options queue: :telegram,
                  rate: {
                    name: 'telegram_rate_limit',
                    limit: 1,
                    period: 1
                  }

  def perform(issue_id, journal_id, user_id)
    logger.debug "START for issue_id #{issue_id}"

    Intouch.set_locale

    issue = Intouch::IssueDecorator.new(Issue.find(issue_id), journal_id, protocol: 'telegram')
    logger.debug issue.inspect

    user = User.find(user_id)
    message = issue.as_html(user_id: user.id)

    logger.debug "user: #{user.inspect}"

    telegram_account = TelegramAccount.find_by!(user_id: user.id)
    logger.debug "telegram_account: #{telegram_account.inspect}"

    logger.debug message

    bot.send_message(text: message,
                     chat_id: telegram_account.telegram_id,
                     parse_mode: 'HTML',
                     **Intouch::Preview::KeyboardMarkup.build_hash(issue_id, journal_id))

    logger.debug "FINISH for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound
    # ignore
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-live-sender.log'))
  end

  def bot
    RedmineBots::Telegram.bot
  end
end
