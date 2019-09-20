module Intouch
  class IssueDecorator < SimpleDelegator

    def initialize(issue, journal_id, protocol:)
      super(issue)
      @journal = journals.find_by(id: journal_id)
      @protocol = protocol
    end

    def as_markdown(user_id: nil)
      message = "#{prefix(user_id) if user_id}\n`#{project.title.gsub(/[`*_]/, '')}: #{subject.gsub(/[`*_]/, '')}`"

      message += "\n#{I18n.t('intouch.telegram_message.issue.updated_by')}: #{updated_by}" if updated_by.present?

      message += "\n#{I18n.t('field_assigned_to')}: #{updated_performer_text}" if updated_details.include?('assigned_to')

      message += bold_for_alarm(updated_priority_text) if updated_details.include?('priority')

      message += "\n#{I18n.t('field_status')}: #{updated_status_text}" if updated_details.include?('status')

      message += "\n#{I18n.t('intouch.telegram_message.issue.updated_details')}: #{updated_details_text}" if updated_details_text.present?

      message += "\n#{I18n.t('field_assigned_to')}: #{performer}" unless updated_details.include?('assigned_to')

      message += bold_for_alarm(priority.name) unless updated_details.include?('priority')

      message += "\n#{I18n.t('field_status')}: #{status.name}" unless updated_details.include?('status')

      message += "\n#{Intouch.issue_url(id)}"

      message
    end

    def as_html(user_id: nil)
      message = "#{prefix(user_id) if user_id}\n<code>#{project.title}: #{subject}</code>"

      message += "\n#{I18n.t('intouch.telegram_message.issue.updated_by')}: #{updated_by}" if updated_by.present?

      message += "\n#{I18n.t('field_assigned_to')}: #{updated_performer_text}" if updated_details.include?('assigned_to')

      message += bold_for_alarm(updated_priority_text, format_strategy: FormatStrategies[:html]) if updated_details.include?('priority')

      message += "\n#{I18n.t('field_status')}: #{updated_status_text}" if updated_details.include?('status')

      message += "\n#{I18n.t('intouch.telegram_message.issue.updated_details')}: #{updated_details_text}" if updated_details_text.present?

      message += "\n#{I18n.t('field_assigned_to')}: #{performer}" unless updated_details.include?('assigned_to')

      message += bold_for_alarm(priority.name, format_strategy: FormatStrategies[:html]) unless updated_details.include?('priority')

      message += "\n#{I18n.t('field_status')}: #{status.name}" unless updated_details.include?('status')

      message += "\n#{Intouch.issue_url(id)}"

      message
    end

    def updated_by
      @journal&.user
    end

    private

    def updated_details
      updated_details = []
      if @journal.present?
        updated_details = @journal.visible_details.map do |detail|
          if detail.property == 'attr'
            detail.prop_key.to_s.gsub(/_id$/, '')
          elsif detail.property == 'cf'
            detail.prop_key.to_i
          elsif detail.property == 'attachment'
            'attachment'
          end
        end
        updated_details << 'notes' if @journal.notes.present?
      end
      updated_details
    end

    def updated_details_text
      if updated_details.present?
        (updated_details - %w(priority status assigned_to)).map do |field|
          if field.is_a? String
            if field == 'attachment'
              I18n.t('label_attachment')
            else
              I18n.t(('field_' + field).to_sym)
            end
          elsif field.is_a? Fixnum
            CustomField.find(field).try(:name)
          end
        end.join(', ')
      end
    end

    def updated_priority_text
      priority_journal = @journal.details.find_by(prop_key: 'priority_id')
      old_priority = IssuePriority.find(priority_journal.old_value)
      "#{old_priority.name} -> #{priority.name}"
    end

    def updated_performer_text
      performer_journal = @journal.details.find_by(prop_key: 'assigned_to_id')
      if performer_journal.old_value
        old_performer = Principal.find performer_journal.old_value
        "#{old_performer.name} -> #{performer}"
      else
        "#{I18n.t('intouch.telegram_message.issue.performer.unassigned')} -> #{performer}"
      end
    end

    def updated_status_text
      status_journal = @journal.details.find_by(prop_key: 'status_id')
      old_status = IssueStatus.find status_journal.old_value
      "#{old_status.name} -> #{status.name}"
    end

    def required_recipients
      @required_recipients ||= Intouch::Live::Checker::Private.new(self, project).required_recipients
    end

    def prefix(user_id)
      roles_in_issue = []

      roles_in_issue << 'assigned_to' if assigned_to_id == user_id
      roles_in_issue << 'watchers' if watchers.pluck(:user_id).include? user_id
      roles_in_issue << 'author' if author_id == user_id

      settings = project.public_send("active_#{@protocol}_settings")

      if settings.present?
        recipients = settings.select do |key, value|
          %w(author assigned_to watchers).include?(key) &&
            value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
        end.keys

        roles_for_prefix(recipients, roles_in_issue).map do |role|
          I18n.t("intouch.telegram_message.recipient.#{role}")
        end.join(', ')
      else
        ''
      end
    end

    def roles_for_prefix(recipients, roles_in_issue)
      return roles_in_issue & recipients unless required_recipients.present?

      roles_in_issue & recipients & required_recipients
    end
  end
end

