module Intouch::Regular::Message
  class Private < Base
    def initialize(issue:, user:, state:, project:)
      @issue = issue
      @user = user
      @state = state
      @project = project

      Intouch.set_locale
    end

    attr_reader :issue, :user, :state, :project

    def send
      return unless telegram_account.present?

      logger.info '========================================='
      logger.info "Notification for state: #{state}"
      logger.info message
      logger.debug issue.inspect
      logger.debug user.inspect
      logger.info '========================================='

      TelegramMessageSender.perform_async(telegram_account.telegram_id.to_i, message)
    end

    def telegram_account
      @telegram_account ||= TelegramAccount.find_by(user_id: user.id)
    end

    def message
      prefix.present? ? "#{prefix}\n#{base_message}" : base_message
    end

    def prefix
      return nil unless settings.present?

      recipients_prefix
    end

    def recipients_prefix
      (roles_in_issue & recipients).map do |role|
        I18n.t("intouch.telegram_message.recipient.#{role}")
      end.join(', ')
    end

    def roles_in_issue
      roles_in_issue = []

      roles_in_issue << 'assigned_to' if issue.assigned_to_id == user.id
      roles_in_issue << 'watchers' if issue.watchers.pluck(:user_id).include? user.id
      roles_in_issue << 'author' if issue.author_id == user.id
      roles_in_issue
    end

    def recipients
      settings.select do |key, _value|
        %w(author assigned_to watchers).include?(key)
      end.keys
    end

    def settings
      @settings ||= project.active_telegram_settings.try(:[], state)
    end

    def logger
      @logger ||= Logger.new(Rails.root.join('log/intouch', 'regular-message-private.log'))
    end
  end
end
