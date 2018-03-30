module Intouch::Live::Handler
  class UpdatedIssue
    def initialize(journal)
      @journal = journal
      @issue = @journal.issue
      @project = @issue.project
    end

    def call
      logger.debug journal.inspect
      logger.debug issue.inspect

      return unless notification_required?

      logger.info 'notification required'

      send_private_messages
      send_group_messages
    end

    private

    attr_reader :issue, :project, :journal

    def notification_required?
      Intouch::Live::Checker::Base.new(
        issue: issue,
        project: project,
        journal: journal
      ).required?
    end

    def send_private_messages
      Intouch::Live::Message::Private.new(issue, project).send
    end

    def send_group_messages
      return unless need_group_message?

      Intouch::Live::Message::Group.new(issue, project).send
    end

    def need_group_message?
      (journal.details.pluck(:prop_key) & %w[priority_id status_id project_id]).present?
    end

    def logger
      @logger ||= Logger.new(Rails.root.join('log/intouch', 'live-updated.log'))
    end
  end
end
