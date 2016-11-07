module Intouch
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # noinspection RubyArgCount
          store :intouch_data, accessors: %w(last_notification)

          after_create :send_new_message

          def self.alarms
            Issue.where(priority_id: IssuePriority.alarm_ids)
          end

          def self.working
            Issue.where(status_id: IssueStatus.working_ids)
          end

          def self.feedbacks
            Issue.where(status_id: IssueStatus.feedback_ids)
          end
        end
      end

      module InstanceMethods
        def alarm?
          IssuePriority.alarm_ids.include? priority_id
        end

        def unassigned?
          assigned_to.nil?
        end

        def assigned_to_group?
          assigned_to.class == Group
        end

        def total_unassigned?
          unassigned? || assigned_to_group? || !project.assigner_ids.include?(assigned_to_id)
        end

        def working?
          IssueStatus.working_ids.include? status_id
        end

        def feedback?
          IssueStatus.feedback_ids.include? status_id
        end

        def without_due_date?
          !due_date.present? && created_on < 1.day.ago
        end

        def notification_state
          %w(unassigned assigned_to_group overdue without_due_date working feedback).select { |s| send("#{s}?") }.try :first
        end

        def notification_states
          %w(unassigned assigned_to_group overdue without_due_date working feedback).select { |s| send("#{s}?") }
        end

        def notificable_for_state?(state)
          case state
          when 'unassigned'
            notification_states.include?('unassigned') || notification_states.include?('assigned_to_group')
          when 'overdue'
            notification_states.include?('overdue') || notification_states.include?('without_due_date')
          when 'working'
            notification_states.include?('working')
          when 'feedback'
            notification_states.include?('feedback')
          else
            false
          end
        end

        def recipient_ids(protocol, state = notification_state)
          if project.send("active_#{protocol}_settings") && state && project.send("active_#{protocol}_settings")[state]
            project.send("active_#{protocol}_settings")[state].map do |key, value|
              case key
              when 'author'
                author.id
              when 'assigned_to'
                if assigned_to.class == Group
                  # assigned_to.user_ids
                else
                  assigned_to_id if project.assigner_ids.include?(assigned_to_id)
                end
              when 'watchers'
                watchers.pluck(:user_id)
              when 'user_groups'
                Group.where(id: value).map(&:user_ids).flatten if value.present?
              end
            end.flatten.uniq + [assigner_id]
          end
        end

        def live_recipient_ids(protocol)
          settings = project.send("active_#{protocol}_settings")
          if settings.present?
            recipients = settings.select { |k, _v| %w(author assigned_to watchers).include? k }

            user_ids = []
            recipients.each_pair do |key, value|
              next unless value.try(:[], status_id.to_s).try(:include?, priority_id.to_s)
              case key
              when 'author'
                user_ids << author.id
              when 'assigned_to'
                if assigned_to.class == Group
                  # user_ids += assigned_to.user_ids
                else
                  user_ids << assigned_to_id if project.assigner_ids.include?(assigned_to_id)
                end
              when 'watchers'
                user_ids += watchers.pluck(:user_id)
              end
            end
            user_ids.flatten.uniq + [assigner_id] - [updated_by.try(:id)] # Не отправляем сообщение тому, то обновил задачу
          else
            []
          end
        end

        def intouch_recipients(protocol, state = notification_state)
          User.where(id: recipient_ids(protocol, state))
        end

        def intouch_live_recipients(protocol)
          User.where(id: live_recipient_ids(protocol))
        end

        def performer
          assigned_to.present? ? assigned_to.name : I18n.t('intouch.telegram_message.issue.performer.unassigned')
        end

        def assigner_id
          if project.assigner_ids.include? assigned_to_id
            assigned_to_id
          else
            journals.order(:id).where(user_id: project.assigner_ids).last.try :user_id
          end
        end

        def assigners_updated_on
          assigners_updated_on = journals.order(:id).where(user_id: project.assigner_ids).last.try :created_on
          assigners_updated_on.present? ? assigners_updated_on : updated_on
        end

        def inactive?
          reminder_settings = project.active_intouch_settings
                                .try(:[], 'reminder_settings')
                                .try(:[], "#{priority_id}")
          active = reminder_settings.try(:[], 'active')
          interval = reminder_settings.try(:[], 'interval')
          active && interval.present? && assigners_updated_on < interval.to_i.hours.ago
        end

        def inactive_message
          hours = ((Time.now - assigners_updated_on) / 3600).round(1)
          I18n.t 'intouch.telegram_message.issue.inactive', hours: hours
        end

        def updated_by
          last_journal.user if journals.present?
        end

        def updated_details
          updated_details = []
          if last_journal.present?
            updated_details = last_journal.visible_details.map do |detail|
              if detail.property == 'attr'
                detail.prop_key.to_s.gsub(/_id$/, '')
              elsif detail.property == 'cf'
                detail.prop_key.to_i
              elsif detail.property == 'attachment'
                'attachment'
              end
            end
            updated_details << 'notes' if last_journal.notes.present?
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

        def updated_performer_text
          performer_journal = last_journal.details.find_by(prop_key: 'assigned_to_id')
          if performer_journal.old_value
            old_performer = Principal.find performer_journal.old_value
            "#{old_performer.name} -> #{performer}"
          else
            "#{I18n.t('intouch.telegram_message.issue.performer.unassigned')} -> #{performer}"
          end
        end

        def updated_priority_text
          priority_journal = last_journal.details.find_by(prop_key: 'priority_id')
          old_priority = IssuePriority.find priority_journal.old_value
          "#{old_priority.name} -> #{priority.name}"
        end

        def updated_status_text
          status_journal = last_journal.details.find_by(prop_key: 'status_id')
          old_status = IssueStatus.find status_journal.old_value
          "#{old_status.name} -> #{status.name}"
        end

        def bold_for_alarm(text)
          if alarm?
            "\n*#{I18n.t('field_priority')}: !!! #{text} !!!*"
          else
            "\n#{I18n.t('field_priority')}: #{text}"
          end
        end

        def telegram_live_message
          message = "`#{project.title}: #{subject}`"

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

        def telegram_message
          message = <<~TEXT
                `#{project.title}: #{subject}`
                #{I18n.t('field_assigned_to')}: #{performer}#{bold_for_alarm(priority.name)}
            #{I18n.t('field_status')}: #{status.name}
            #{Intouch.issue_url(id)}
          TEXT
          message = "*!!! #{inactive_message} !!!*\n#{message}" if inactive?
          message = "*!!! #{I18n.t('intouch.telegram_message.issue.notice.without_due_date')} !!!* \n#{message}" if without_due_date?
          message = "*!!! #{I18n.t('intouch.telegram_message.issue.notice.overdue')} !!!*  \n#{message}" if overdue?
          message = "*!!! #{I18n.t('intouch.telegram_message.issue.notice.unassigned')} !!!* \n#{message}" if unassigned? || assigned_to_group?
          message
        end

        def last_journal
          @last_journal ||= journals.order(:id).last
        end

        private

        def send_new_message
          if project.module_enabled?(:intouch) && project.active? && !closed?

            if alarm? || Intouch.work_time?

              IntouchSender.send_live_telegram_message(id) if Intouch.active_protocols.include? 'telegram'

              IntouchSender.send_live_email_message(id) if Intouch.active_protocols.include? 'email'

            end

            if Intouch.active_protocols.include? 'telegram'
              IntouchSender.send_live_telegram_group_message(id)
            end
          end
        end
      end
    end
  end
end
Issue.send(:include, Intouch::Patches::IssuePatch)
