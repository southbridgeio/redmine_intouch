require_dependency 'projects_helper'

module Intouch
  module Patches
    module ProjectsHelperPatch
      def project_settings_tabs
        tabs = super

        return tabs unless User.current.allowed_to?(:manage_intouch_settings, @project)

        tabs.push(
            name: 'intouch_settings',
            action: :manage_intouch_settings,
            partial: 'projects/settings/intouch/settings',
            label: 'intouch.label.settings'
        )

        tabs
      end
    end
  end
end

unless ProjectsHelper.ancestors.include?(Intouch::Patches::ProjectsHelperPatch)
  ProjectsHelper.prepend(Intouch::Patches::ProjectsHelperPatch)
end
