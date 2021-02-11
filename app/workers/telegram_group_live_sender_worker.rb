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
    end.keys.to_set

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

    subscription_group_id = TelegramGroupChat.find_by_tid(Intouch::TelegramChatSubscription.find_by(issue_id: issue.id)&.chat_id)&.id
    group_for_send_ids << subscription_group_id if subscription_group_id

    return unless group_for_send_ids.present?

    message = issue.as_html

    logger.debug "message: #{message}"

    group_for_send_ids.each do |group_id|
      TelegramGroupMessageSender.perform_async(group_id, message, issue_id, journal_id)
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-group-live-sender.log'))
  end
end
