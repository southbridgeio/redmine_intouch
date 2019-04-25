module Intouch
  class IssueUpdate
    attr_reader :issue, :journal

    def initialize(issue, journal, protocol_name)
      @journal, @protocol_name = journal, protocol_name
      @issue = IssueDecorator.new(issue, journal&.id, protocol: protocol_name)
    end

    def live_recipients
      return [] unless need_notification?
      @live_recipients ||= User.where(id: live_recipient_ids(@protocol_name)).to_a + [customer(@protocol_name)].compact
    end

    private

    def live_recipient_ids(protocol)
      settings = issue.project.send("active_#{protocol}_settings")
      return [] if settings.blank?
      recipients = settings.select { |k, _| %w(author assigned_to watchers).include? k }

      subscribed_user_ids = IntouchSubscription.where(project_id: issue.project_id).select(&:active?).map(&:user_id)

      user_ids = []
      recipients.each_pair do |key, value|
        next unless value.try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
        case key
        when 'author'
          user_ids << issue.author.id
        when 'assigned_to'
          user_ids << issue.assigned_to_id if issue.assigned_to.class == User
        when 'watchers'
          user_ids += issue.watchers.pluck(:user_id)
        end
      end
      (user_ids.flatten + [issue.assigner_id] + subscribed_user_ids - [User.anonymous.id] - [issue.updated_by&.id]).uniq
    end

    def customer(protocol)
      return unless protocol == 'email' && issue.project.module_enabled?(:contacts)

      settings = issue.project.send("active_#{protocol}_settings")
      return if settings.blank?

      recipients = settings.select { |k, _| %w(author).include? k }

      return unless recipients['author'].try(:[], issue.status_id.to_s).try(:include?, issue.priority_id.to_s)
      issue.customer
    end

    def need_notification?
      Intouch::Live::Checker::Private.new(issue, issue.project).required?
    end
  end
end
