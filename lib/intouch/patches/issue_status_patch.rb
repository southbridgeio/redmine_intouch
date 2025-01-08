module Intouch
  module Patches
    module IssueStatusPatch
      def self.included(base) # :nodoc:
        base.class_eval do

          def self.feedback_ids
            settings = Setting.plugin_redmine_intouch
            settings.keys.select { |key| key.include?('feedback_status') }.map { |key| key.split('_').last.to_i }
          end

          def self.working_ids
            settings = Setting.plugin_redmine_intouch
            settings.keys.select { |key| key.include?('working_status') }.map { |key| key.split('_').last.to_i }
          end
        end
      end
    end
  end
end
IssueStatus.send(:include, Intouch::Patches::IssueStatusPatch)
