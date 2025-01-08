class SettingsTemplate < ActiveRecord::Base

  store :intouch_settings, accessors: %w[assigner_groups assigner_roles reminder_settings] | Intouch.protocols.keys.map { |p| "#{p}_settings" }

  def copy_from(settings_template)
    self.attributes = settings_template.attributes.dup.except('id', 'created_on', 'updated_on')
    self.name += ' COPY'
    self
  end
end
