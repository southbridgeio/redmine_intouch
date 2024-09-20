# 1.6.1

* Change foreign key to issue
* Add compatibility with Redmine 5.1

# 1.6.0

* Send live notifications for closed issues
* Add lazy loading for telegram chats
* Refactor commands
* Add individual chat subscriptions for issues

# 1.5.1

* Remove sidekiq-rate-limiter from gemfile
* Remove ruby 2.7.0 from build matrix

# 1.5.0

* Add plugins deprecation warning
* Fix project settings page performance
* Implement message previews
* Don’t send updates to updated_by
* Don’t send live updates to inactive users
* Handle telegram group upgrade errors
* Set telegram rate limiting
* Use html formatting in telegram
* Fix idempotency

# 1.4.0

* Adapt for Redmine 4
* Fix settings caching issues in sidekiq

# 1.3.0

* Use redmine_bots instead of redmine_telegram_common
* Add Slack support (and transparent support for custom protocols)
* Fix redmine_helpdesk integration

# 1.2.1

* Fix helpdesk support

# 1.2.0

* Fix rack-protection issue
* Add time zone notice to cron jobs edit page
* Add assigner_roles setting
* Add /notify command
* Add redmine_telegram_common dependency

# 1.1.1

* Fix status update message
* Send issue project updates to groups
* Add redmine-helpdesk support

# 1.1.0

* Update telegram-bot-ruby
* Use bot from redmine_telegram_common

# 1.0.2

* Fix circular dependency issues
* Add bot collision check
* Don't send notifications to non-active users
* Fix status update message

# 1.0.1

* Add Rails 5.1 support
* Fix uninitialized constant TelegramMessageSender::Telegram
* Remove git usage in plugin code
* Fix LiveHandlerWorker not found issue
* Fix mail from field

# 1.0.0

* Upgrade redmine_telegram_common to version 0.1.0
* Move from telegrammer to telegram-bot-ruby
* Telegram bot can work via getUpdates or WebHooks
* Telegram rake bot will bind default to tmp/pids

# 0.6.2

* Add support sidekiq 5 version

# 0.6.1

* Fix regular recipients list, add logging to regular group sender worker

# 0.6.0

* Regular and live message refactoring and tuning
* Fix issues [#33](https://github.com/centosadmin/redmine_intouch/issues/33) and [#43](https://github.com/centosadmin/redmine_intouch/issues/43)

# 0.5.3

* Fix: Always send live message for required recipients for settings template

# 0.5.2

* `without_due_date?` regression hot fix

# 0.5.1

* Extract regular notification text to service class

# 0.5.0

* New feature: Always send live message for required recipients

# 0.4.1

* Fix projects helper patch

# 0.4.0

* Update for use [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common) version 0.0.12

# 0.3.3

* Add help command

# 0.3.1

* Add exception notification on bot restart

# 0.3.0

Migrate to [redmine_telegram_common](https://github.com/centosadmin/redmine_telegram_common) plugin.
* before upgrade please install [this](https://github.com/centosadmin/redmine_telegram_common) plugin.
* run `bundle exec rake intouch:common:migrate` after upgrade

# 0.2.0
* Add checkboxes for select all priorities and statuses
* Add copy settings template feature
