FileUtils.mkdir_p(Rails.root.join('log/intouch')) unless Dir.exist?(Rails.root.join('log/intouch'))

require 'intouch'

ActionDispatch::Callbacks.to_prepare do
  paths = '/lib/intouch/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :redmine_intouch do
  name 'Redmine Intouch plugin'
  url 'https://github.com/olemskoi/redmine_intouch'
  description 'This is a plugin for Redmine which sends a reminder email and Telegram messages to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '0.3.5'
  author 'Centos-admin.ru'
  author_url 'http://centos-admin.ru'

  requires_redmine version_or_higher: '3.0'

  settings(default: { 'active_protocols' => %w(email), 'work_day_from' => '10:00', 'work_day_to' => '18:00' },
           partial: 'settings/intouch')

  project_module :intouch do
    permission :manage_intouch_settings, projects: :settings,
                                         intouch_settings: :save
  end
end
