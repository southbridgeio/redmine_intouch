require_dependency Rails.root.join('plugins','redmine_bots', 'init')

FileUtils.mkdir_p(Rails.root.join('log/intouch')) unless Dir.exist?(Rails.root.join('log/intouch'))

require './plugins/redmine_intouch/lib/intouch'
require 'telegram/bot'

register_after_redmine_initialize_proc =
  if Redmine::VERSION::MAJOR >= 5
    Rails.application.config.public_method(:after_initialize)
  else
    reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
    reloader.public_method(:to_prepare)
  end
register_after_redmine_initialize_proc.call do
  paths = '/lib/intouch/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end

  require_dependency './plugins/redmine_bots/lib/redmine_bots'
end

paths = Dir.glob("#{Rails.application.config.root}/plugins/redmine_intouch/{lib,app/workers,app/models,app/controllers}")

Rails.application.config.eager_load_paths += paths
Rails.application.config.autoload_paths += paths
ActiveSupport::Dependencies.autoload_paths += paths

Intouch.bootstrap

Redmine::Plugin.register :redmine_intouch do
  name 'Redmine Intouch plugin'
  url 'https://github.com/southbridgeio/redmine_intouch'
  description 'This is a plugin for Redmine which sends a reminder email and Telegram messages to the assignee workign on a task, whose status is not updated with-in allowed duration'
  version '1.7.0'
  author 'Southbridge'
  author_url 'https://github.com/southbridgeio'

  requires_redmine version_or_higher: '3.0'

  requires_redmine_plugin :redmine_bots, '0.6.0'

  settings(
    default: {
      'active_protocols' => %w(email),
      'work_day_from' => '10:00',
      'work_day_to' => '18:00',
      'telegram_preview' => '1'
    },
    partial: 'settings/intouch')

  project_module :intouch do
    permission :manage_intouch_settings,
      projects: :settings,
      intouch_settings: :save
  end
end

# Eager load throttled workers for Sidekiq Web UI
# Load these workers to register them in Sidekiq::Throttled::Registry
Rails.application.config.after_initialize do
  %w[
    telegram_message_sender
    telegram_group_message_sender
    telegram_group_sender_worker
    telegram_live_sender_worker
  ].each do |worker|
    require_dependency worker rescue nil
  end
end
