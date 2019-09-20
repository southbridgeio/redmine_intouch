module Intouch
  module Message
    class Formatter
      attr_reader :issue, :project, :format_strategy # , :status, :priority

      def initialize(issue, format_strategy: FormatStrategies[:html])
        @issue = issue
        @project = @issue.project
        @status = @issue.status
        @priority = @issue.priority
        @format_strategy = format_strategy
      end

      def title
        "#{project.title}: #{issue.subject}"
      end

      def assigned_to
        "#{I18n.t('field_assigned_to')}: #{performer}"
      end

      def priority
        if issue.alarm?
          format_strategy.bold("#{I18n.t('field_priority')}: !!! #{@priority.name} !!!")
        else
          "#{I18n.t('field_priority')}: #{@priority.name}"
        end
      end

      def status
        "#{I18n.t('field_status')}: #{@status.name}"
      end

      def link
        Intouch.issue_url(issue.id)
      end

      def performer
        @performer ||= issue.performer
      end

      def attention(text)
        format_strategy.bold("!!! #{text} !!!")
      end

      def bold(text)
        format_strategy.bold("#{text}")
      end
    end
  end
end
