module Intouch::Protocols
  class Telegram < Base
    def handle_update(update)
      issue = update.issue
      journal = update.journal

      update.live_recipients.each do |user|
        TelegramLiveSenderWorker.perform_async(issue.id, journal&.id, user.id)
      end

      TelegramGroupLiveSenderWorker.perform_in(5.seconds, issue.id, journal&.id) if need_group_message?(journal)
    end

    def send_regular_notification(issue, state)
      project = issue.project
      telegram_settings = project.active_telegram_settings

      TelegramSenderWorker.perform_in(5.seconds, issue.id, state)

      group_ids = telegram_settings.try(:[], state).try(:[], 'groups')
      group_ids.each { |id| TelegramGroupSenderWorker.perform_async(issue.id, id, state) }
    end
  end
end
