class TelegramGroupLiveSenderWorker
  include Sidekiq::Worker

  def perform(issue_id, new_alarm = false)
    logger.debug "START for issue_id #{issue_id}"
    Intouch.set_locale

    issue = Issue.find issue_id
    logger.debug issue.inspect

    telegram_groups_settings = issue.project.active_telegram_settings.try(:[], 'groups')

    return unless telegram_groups_settings.present?

    logger.debug "telegram_groups_settings: #{telegram_groups_settings.inspect}"

    group_ids = groups_for_status_and_priority(issue, telegram_groups_settings)

    logger.debug "group_ids: #{group_ids.inspect}"

    group_ids = remove_only_unassigned_groups(group_ids, telegram_groups_settings) unless issue.total_unassigned?

    logger.debug "group_ids: #{group_ids.inspect} (total_unassigned? = #{issue.total_unassigned?.inspect})"

    group_ids += new_alarm_groups(telegram_groups_settings) if new_alarm

    group_for_send_ids = group_for_send_ids(group_ids, issue, telegram_groups_settings)

    logger.debug "group_for_send_ids: #{group_for_send_ids.inspect}"

    return unless group_for_send_ids.present?

    message = issue.telegram_live_message

    logger.debug "message: #{message}"

    TelegramGroupChat.where(id: group_for_send_ids).uniq.each do |group|
      logger.debug "group: #{group.inspect}"
      next unless group.tid.present?

      job = TelegramMessageSender.perform_async(-group.tid, message)

      logger.debug job.inspect
    end
    logger.debug "DONE for issue_id #{issue_id}"
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-group-live-sender.log'))
  end

  def group_for_send_ids(group_ids, issue, settings)
    if issue.alarm? || Intouch.work_time?
      logger.debug 'Alarm or work time'

      group_ids

    else
      logger.debug 'Anytime notifications'

      anytime_group_ids = settings.select { |_k, v| v.try(:[], 'anytime').present? }.keys

      (group_ids & anytime_group_ids)
    end
  end

  def groups_for_status_and_priority(issue, settings)
    settings.select do |_k, v|
      v.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
    end.keys
  end

  def remove_only_unassigned_groups(group_ids, settings)
    only_unassigned_group_ids = settings.select { |_k, v| v.try(:[], 'only_unassigned').present? }.keys
    logger.debug "only_unassigned_group_ids: #{group_ids.inspect}"

    group_ids - only_unassigned_group_ids
  end

  def new_alarm_groups(settings)
    settings.select { |_k, v| v.try(:[], 'new_alarm_required').present? }.keys
  end
end
