module Intouch
  module Patches
    module JournalPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          after_create :send_live_message

          private

          def send_live_message
            project = issue.project
            if project.module_enabled?(:intouch) && project.active?
              if Intouch.work_time? || issue.alarm?
                if Intouch.active_protocols.include? 'telegram'

                  if (details.pluck(:prop_key) & %w(priority_id status_id)).present?
                    IntouchSender.send_live_telegram_group_message(issue.id, new_alarm)
                  end

                  IntouchSender.send_live_telegram_message(issue.id)
                end

                IntouchSender.send_live_email_message(issue.id) if Intouch.active_protocols.include? 'email'
              end
            end
          end

          def new_alarm
            issue.alarm? && details.find_by(prop_key: 'priority_id').present?
          end
        end
      end
    end
  end
end
Journal.send(:include, Intouch::Patches::JournalPatch)
