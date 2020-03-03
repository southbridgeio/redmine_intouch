module Intouch::Live::Checker
  class Base
    attr_reader :project, :issue, :journal

    def initialize(issue:, project:, journal: nil)
      @issue = issue
      @project = project
      @journal = journal

      logger.info 'Initialized with:'
      logger.debug "Issue: #{issue.inspect}"
      logger.debug "Project: #{project.inspect}"
      logger.debug "Journal: #{journal.inspect}"
    end

    def required?
      project_enabled?
    end

    def project_enabled?
      logger.info 'Project enabled?'

      logger.debug "project.module_enabled?(:intouch) => #{project.module_enabled?(:intouch).inspect}"
      logger.debug "project.active? => #{project.active?.inspect}"

      project.module_enabled?(:intouch) && project.active?
    end

    def issue_open?
      logger.debug "!issue.closed? => #{!issue.closed?.inspect}"

      !issue.closed? || journal_issue_state_open?
    end

    def journal_issue_state_open?
      logger.debug "journal.present? => #{journal.present?.inspect}"
      return false unless journal.present?

      logger.debug "journal.new_status => #{journal.new_status.inspect}"
      logger.debug "!journal.new_status&.is_closed? => #{!journal.new_status&.is_closed?.inspect}"

      journal.new_status && !journal.new_status&.is_closed?
    end

    private

    def logger
      @logger ||= Logger.new(Rails.root.join('log/intouch', 'live-checker-base.log'))
    end
  end
end
