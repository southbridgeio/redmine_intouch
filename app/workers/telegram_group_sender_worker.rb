class TelegramGroupSenderWorker
  include Sidekiq::Worker

  sidekiq_options queue: :telegram,
                  rate: {
                    name: 'telegram_rate_limit',
                    limit: 1,
                    period: 4
                  }

  def perform(issue_id, group_id, state)
    return unless group_id.present?

    @issue = Issue.find_by(id: issue_id)
    @group_id = group_id
    @state = state

    return unless @issue.present?
    return unless notificable?
    return unless group.present?

    log

    Intouch.handle_group_upgrade(group) { |chat| send_message(chat) }
  end

  private

  attr_reader :issue, :state, :group_id

  def notificable?
    Intouch::Regular::Checker::Base.new(
      issue: issue,
      state: state,
      project: project
    ).required?
  end

  def group
    @group ||= ::TelegramGroupChat.find_by(id: group_id)
  end

  def send_message(group)
    return unless group.tid.present?
    RedmineBots::Telegram::Bot::MessageSender.call(message: message,
                                                   chat_id: -group.tid,
                                                   parse_mode: 'HTML')
  end

  def message
    @message ||= issue.telegram_message
  end

  def project
    @project ||= issue.project
  end

  def log
    logger.info '========================================='
    logger.info "Notification for state: #{state}"
    logger.info message
    logger.debug issue.inspect
    logger.debug group_id.inspect
    logger.info '========================================='
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/intouch', 'telegram-group-sender.log'))
  end
end
