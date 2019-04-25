class TelegramGroupLiveSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, journal_id)
    logger.debug "START for issue_id #{issue_id}"
    Intouch.set_locale

    issue = Intouch::IssueDecorator.new(Issue.find(issue_id), journal_id, protocol: 'telegram')
    logger.debug issue.inspect

    telegram_groups_settings = issue.project.active_telegram_settings.try(:[], 'groups')
    logger.debug "telegram_groups_settings: #{telegram_groups_settings.inspect}"

    return unless telegram_groups_settings.present?

    group_ids = telegram_groups_settings.select do |_k, v|
      v.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
    end.keys

    logger.debug "group_ids: #{group_ids.inspect}"

    only_unassigned_group_ids = telegram_groups_settings.select { |_k, v| v.try(:[], 'only_unassigned').present? }.keys

    logger.debug "only_unassigned_group_ids: #{group_ids.inspect}"

    group_ids -= only_unassigned_group_ids unless issue.total_unassigned?

    logger.debug "group_ids: #{group_ids.inspect} (total_unassigned? = #{issue.total_unassigned?.inspect})"

    group_for_send_ids = if issue.alarm? || Intouch.work_time?
                           logger.debug 'Alarm or work time'

                           group_ids

                         else
                           logger.debug 'Anytime notifications'

                           anytime_group_ids = telegram_groups_settings.select { |_k, v| v.try(:[], 'anytime').present? }.keys

                           (group_ids & anytime_group_ids)
                         end

    logger.debug "group_for_send_ids: #{group_for_send_ids.inspect}"

    return unless group_for_send_ids.present?

    message = issue.as_markdown

    logger.debug "message: #{message}"

    TelegramGroupChat.where(id: group_for_send_ids).uniq.each do |group|
      logger.debug "group: #{group.inspect}"
      next unless group.tid.present?

      keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: [
              [
                  Telegram::Bot::Types::InlineKeyboardButton.new(text: I18n.t('label_preview'),
                                                                 callback_data: { type: 'issue_preview', issue_id: issue_id }.to_json)
              ]
          ]
      )

      reply_markup = Intouch.telegram_preview? ? { reply_markup: keyboard } : {}
      RedmineBots::Telegram::Bot::MessageSender.call(message: message,
                                                     chat_id: -group.tid,
                                                     parse_mode: 'Markdown',
                                                     **reply_markup)
    end
    logger.debug "DONE for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-group-live-sender.log'))
  end
end
