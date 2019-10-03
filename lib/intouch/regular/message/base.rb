module Intouch::Regular::Message
  class Base
    extend Intouch::ServiceInitializer
    include ActionView::Helpers::SanitizeHelper

    attr_reader :issue

    delegate :title, :assigned_to, :priority, :status, :link, :bold,
             to: :formatter

    def initialize(issue)
      @issue = issue

      Intouch.set_locale
    end

    def base_message
      @base_message ||= [
        unassigned_message,
        overdue_message,
        without_due_date_message,
        inactive_message,
        basic_message
      ].compact.join("\n")
    end

    def basic_message
      <<~TEXT
        <code>#{sanitize(title)}</code>
        #{sanitize(assigned_to)}
        #{sanitize(priority)}
        #{sanitize(status)}
        #{link}
      TEXT
    end

    def unassigned_message
      return unless issue.unassigned? || issue.assigned_to_group?

      I18n.t('intouch.telegram_message.issue.notice.unassigned')
    end

    def overdue_message
      return unless issue.overdue?

      I18n.t('intouch.telegram_message.issue.notice.overdue')
    end

    def without_due_date_message
      return unless without_due_date?

      I18n.t('intouch.telegram_message.issue.notice.without_due_date')
    end

    def inactive_message
      return unless inactive?

      bold I18n.t('intouch.telegram_message.issue.inactive', hours: rounded_inactive_hours)
    end

    def without_due_date?
      !issue.due_date.present? && issue.created_on < 1.day.ago
    end

    def rounded_inactive_hours
      inactive_hours.round(1)
    end

    def inactive?
      return unless reminder_active? && reminder_interval.positive?

      inactive_hours >= reminder_interval
    end

    def inactive_hours
      @inactive_hours ||= ((Time.now - latest_action_on) / 3600)
    end

    def reminder_interval
      reminder_settings.try(:[], 'interval').to_i
    end

    def reminder_active?
      reminder_settings.try(:[], 'active')
    end

    def reminder_settings
      @reminder_settings ||= project.active_intouch_settings
                               .try(:[], 'reminder_settings')
                               .try(:[], issue.priority_id.to_s)
    end

    def latest_action_on
      latest_staff_action_on.present? ? latest_staff_action_on : issue.updated_on
    end

    def latest_staff_action_on
      @latest_assigner_update_on ||=
        issue.journals.order(:id).where(user_id: project.assigner_ids).last.try(:created_on)
    end

    def formatter
      @formatter ||= Intouch::Message::Formatter.new(issue)
    end

    def project
      @project ||= issue.project
    end
  end
end
