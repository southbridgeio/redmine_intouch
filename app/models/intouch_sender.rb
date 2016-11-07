class IntouchSender
  unloadable

  def self.send_email_message(issue_id, state)
    EmailSenderWorker.perform_in(5.seconds, issue_id, state)
  end

  def self.send_telegram_message(issue_id, state)
    TelegramSenderWorker.perform_in(5.seconds, issue_id, state)
  end

  def self.send_telegram_group_message(issue_id, group_ids, state)
    TelegramGroupSenderWorker.perform_in(5.seconds, issue_id, group_ids, state)
  end

  def self.send_live_email_message(issue_id)
    EmailLiveSenderWorker.perform_in(5.seconds, issue_id)
  end

  def self.send_live_telegram_message(issue_id)
    TelegramLiveSenderWorker.perform_in(5.seconds, issue_id)
  end

  def self.send_live_telegram_group_message(issue_id, new_alarm = false)
    TelegramGroupLiveSenderWorker.perform_in(5.seconds, issue_id, new_alarm)
  end
end
