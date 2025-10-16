module Intouch
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.class_eval do

          # noinspection RubyArgCount
          store :intouch_settings, accessors: %w[settings_template_id assigner_groups assigner_roles reminder_settings] | Intouch.protocols.keys.map { |p| "#{p}_settings" }

          before_create :copy_settings_from_parent

          def assigner_ids
            Group.where(id: active_assigner_groups).try(:map, &:user_ids).try(:flatten).try(:uniq) |
              principals_by_role.select { |role, users| role.id.to_s.in?(active_assigner_roles) }.map(&:last).flatten.uniq.map(&:id)
          end

          def active_assigner_groups
            settings_template ? settings_template.assigner_groups : assigner_groups
          end

          def active_assigner_roles
            (settings_template ? settings_template.assigner_roles : assigner_roles) || []
          end

          def active_reminder_settings
            settings_template ? settings_template.reminder_settings : reminder_settings
          end

          Intouch.protocols.each do |protocol, _|
            define_method("active_#{protocol}_settings") do
              (settings_template ? settings_template.public_send("#{protocol}_settings") : send("#{protocol}_settings")) || {}
            end
          end

          def active_intouch_settings
            settings_template ? settings_template.intouch_settings : intouch_settings
          end

          def settings_template
            @settings_template ||= ::SettingsTemplate.find_by(id: settings_template_id)
          end

          def title
            name
          end

          private

          def copy_settings_from_parent
            self.intouch_settings = parent.intouch_settings if parent.present?
          end
        end
      end
    end
  end
end
Project.send(:include, Intouch::Patches::ProjectPatch)
