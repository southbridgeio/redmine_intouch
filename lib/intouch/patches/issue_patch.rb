module Intouch
  module Patches
    module IssuePatch
      NOTIFICATION_STATES = %w(unassigned assigned_to_group overdue without_due_date working feedback)

      def self.included(base) # :nodoc:
        base.class_eval do

          # noinspection RubyArgCount
          store :intouch_data, accessors: %w(last_notification)

          after_commit :handle_new_issue, on: :create

          def self.alarms
            Issue.where(priority_id: IssuePriority.alarm_ids)
          end

          def self.working
            Issue.where(status_id: IssueStatus.working_ids)
          end

          def self.feedbacks
            Issue.where(status_id: IssueStatus.feedback_ids)
          end

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

          # This method need for `notification_states` and `notification_state`

          def without_due_date?
            !due_date.present? && created_on < 1.day.ago
          end

          def working?
            IssueStatus.working_ids.include? status_id
          end

          def feedback?
            IssueStatus.feedback_ids.include? status_id
          end

          def notification_state
            NOTIFICATION_STATES.select { |s| send("#{s}?") }.try :first
          end

          def notification_states
            NOTIFICATION_STATES.select { |s| send("#{s}?") }
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
            Intouch::Regular::RecipientsList.new(
              issue: self,
              state: state,
              protocol: protocol
            ).recipient_ids
          end

          def intouch_recipients(protocol, state = notification_state)
            Intouch::Regular::RecipientsList.new(
              issue: self,
              state: state,
              protocol: protocol
            ).call
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

          def bold_for_alarm(text, format_strategy: FormatStrategies[:markdown])
            if alarm?
              "\n#{format_strategy.bold("#{I18n.t('field_priority')}: !!! #{text} !!!")}"
            else
              "\n#{I18n.t('field_priority')}: #{text}"
            end
          end

          def telegram_message
            Intouch::Regular::Message::Base.new(self).base_message
          end

          private

          def handle_new_issue
            Intouch::Live::Handler::NewIssue.new(self).call
          end
        end
      end
    end
  end
end
Issue.send(:include, Intouch::Patches::IssuePatch)
