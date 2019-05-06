module Intouch::Preview
  class Handler
    class OutdatedQueryError
      def self.===(e)
        e.is_a?(Telegram::Bot::Exceptions::ResponseError) && e.message.include?('query is too old')
      end
    end

    def self.call(*args)
      api = Telegram::Bot::Api.new(Intouch.bot_token)
      new(api, *args).call
    end

    def self.to_proc
      proc { |*args| call(*args) }
    end

    def initialize(api, update)
      @api = api
      @update = update
    end

    def call
      return unless Intouch.telegram_preview?
      return unless data[:type] == 'issue_preview' && issue && current_user.allowed_to?(:view_issues, project)

      api.answer_callback_query(callback_query_id: update.id, text: preview_text, show_alert: true, cache_time: 30)
    rescue OutdatedQueryError
      # skip
    end

    private

    attr_reader :api, :update

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

    def journal
      @journal ||= Journal.find_by(id: data[:journal_id])
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

    def preview_text
      Text.normalize(issue, journal)
    end
  end
end
