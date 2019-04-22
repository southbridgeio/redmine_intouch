module Intouch
  class PreviewHandler
    extend ServiceInitializer

    def initialize(update)
      @update = update
    end

    def call
      return unless data[:type] == 'issue_preview' && issue && current_user.allowed_to?(:view_issues, project)

      api.answer_callback_query(callback_query_id: update.id, text: preview_text, show_alert: true, cache_time: 30)
    end

    private

    attr_reader :update

    def raw_data
      update.data
    end

    def data
      @data ||= JSON.parse(raw_data).with_indifferent_access
    rescue JSON::ParserError
      {}
    end

    def issue
      @issue ||= Issue.find_by(id: data[:issue_id])
    end

    def project
      issue.project
    end

    def telegram_account
      @telegram_account ||= TelegramAccount.find_by(telegram_id: update.from.id)
    end

    def current_user
      telegram_account&.user || User.anonymous
    end

    def bot
      @bot ||= Telegram::Bot::Client.new(Intouch.bot_token)
    end

    def api
      bot.api
    end

    def sanitizer
      Rails::Html::FullSanitizer.new
    end

    def preview_text
      sanitizer.sanitize(issue.description.presence || issue.journals.last.notes).truncate(200)
    end
  end
end
