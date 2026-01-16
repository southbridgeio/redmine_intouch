[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_intouch)

[Русская версия](README-RU.md)

# redmine_intouch

[![Code Climate](https://codeclimate.com/github/southbridgeio/redmine_intouch/badges/gpa.svg)](https://codeclimate.com/github/southbridgeio/redmine_intouch)
[![Build Status](https://travis-ci.org/southbridgeio/redmine_intouch.svg?branch=master)](https://travis-ci.org/southbridgeio/redmine_intouch)

Plugin is designed to send notifications to Redmine’s users by Telegram or E-mail.

Please help us make this plugin better telling us of any [issues](https://github.com/southbridgeio/redmine_intouch/issues) you'll face using it. We are ready to answer all your questions regarding this plugin.

# Installation

## Requirements

* **Ruby 2.4+**
* **Redmine 3.1+**
* Configured [redmine_bots](https://github.com/southbridgeio/redmine_bots)
* Install [Redis](https://redis.io) 2.8 or higher. Run Redis and add it to autorun.
* Install the [redmine_sidekiq](https://github.com/ogom/redmine_sidekiq) plugin. [Redis](https://redis.io) 2.8 or greater is required.
* You need to configure Sidekiq queues `default` and `telegram`. [Config example](https://github.com/southbridgeio/redmine_intouch/blob/master/extras/sidekiq.yml) - place it to `redmine/config` directory (Or copy from plugins/redmine_intouch/extras/sidekiq.yml to config/sidekiq.yml).
* Standard install plugin:

```
cd {REDMINE_ROOT}
git clone https://github.com/southbridgeio/redmine_intouch.git plugins/redmine_intouch
bundle install RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

The `extras` folder has the examples of the plugin config files and the `init.d` startup script

### Update to version 1.7.0+
Starting with version 1.7.0, the `redmine_intouch` plugin uses the `sidekiq-throttled` gem instead of the `sidekiq-rate-limiter` gem.
You will also need to update the `redmine_bots` plugin to version `0.6.0`.

## Upgrade from 1.3 to 1.4+

v1.4.0 introduces Redmine 4 support. If you're running Redmine 4, you need to run this task:

`RAILS_ENV=production bundle exec rake intouch:fix_settings`

to fix compatibility with Rails 5.

### Upgrade from 1.2 to 1.3+

From 1.3.0 redmine_intouch depends on [redmine_bots](https://github.com/southbridgeio/redmine_bots) instead of redmine_telegram_common.
Make sure to remove redmine_telegram_common from plugins and follow installation instruction for [redmine_bots](https://github.com/southbridgeio/redmine_bots).

### Upgrade from 1.0.2 to 1.1.0+

From 1.1.0 redmine_intouch (as well as other Southbridge telegram plugins) is using bot from redmine_telegram_common.
In order to perform migration to single bot you should run `bundle exec rake telegram_common:migrate_to_single_bot`.
Bot token will be taken from one of installed Southbridge plugins in the following priority:

* redmine_chat_telegram
* redmine_intouch
* redmine_2fa

Also you should re-initialize bot on redmine_telegram_common settings page.
*Note that you need to manually replace old bot with the new one in group chats.*

### Upgrade from 0.3 to 1.0.0+

Since version 1.0.0 this plugin uses [redmine_telegram_common](https://github.com/southbridgeio/redmine_telegram_common)
0.1.0 version, where removed Telegram CLI dependency. Please, take a look on new requirements.

### Upgrade from 0.2 to 0.3+

Since version 0.2 this plugin uses [redmine_telegram_common](https://github.com/southbridgeio/redmine_telegram_common)
plugin.

Before upgrade install [this](https://github.com/southbridgeio/redmine_telegram_common) plugin.

Then upgrade and run `bundle exec rake intouch:common:migrate RAILS_ENV=production` for migrate data to new table.

Since 0.4 version, model `TelegramUser` will be removed, also table `telegram_users` will be removed.

# Plugin Setup

## General settings

You should specify all the necessary notification protocols in the "Protocols" section. These are 'telegram', 'slack' and 'email' available at the moment.

The section "Working days" should contain:

* when the workday starts and when it ends
* what days are considered as workdays

The section "Urgent Tasks" contains the ticket priorities, that will have notifications being sent despite of the time or day of a week.

The plugin contains the fuctionality that allows you to send scheduled notifications tagged as "In work" or "Feedback". Specify these statuses in appropriate sections so the plugin could parse them correctly.

### Bot launch

Specify the following things before launching the bot:

* Working Time - when and what notifications will be sent
* Specify what priorities should be considered as urgent ones
* Specify what statuses should be considered _in work_ and _feedback_
* Save settings

### Adding a Telegram account to the user

User needs to add a bot with `/start` command.

After that the bot prompts to enter the command `/connect account@redmine.com`.

After the command, the user will receive an email with a link.

Following the link will connect the user's accounts.

#### If the bot has been changed

If you have changed the bot, then each user needs to greet it personally.
One has to connect to the new bot if it has been changed. To do that all the participating Users should find the new bot via search and type the `/start` command again.

### Adding a Telegram Group

The groups are added to Redmine, if the bot was added to them.

The group name is saved on addition. Issue the `/rename` command in the group chat to change the group name in Redmine.

### Available commands

- `/help` - list of available commands with its descriptions

**Private chat with bot**

- `/connect e@mail.com` - connect Telegram and Redmine accounts
- `/update` - update Telegram account info (after change name or username)

**Group chat**

- `/update` - update group name (after change Telegram group name)

#### Hints for bot commands

Use command `/setcommands` with [@BotFather](https://telegram.me/botfather). Send this list for setup hints:

```
start - Start work with bot
connect - Connect Redmine and Telegram account
update - Update Telegram account info or group name
help - Help about commands
```

## Settings Templates

The settings templates allow you to set all the required project settings once, and then just choose the right template for each project.
Read below of the settings of the plugin integrated into the project.

## Regular Notifications Schedule

The plugin is provided with:

* Notification about issues with the "In work" status;
* Notification about issues with the "Feedback" status;
* Notifications about unassigned issues;
* Notifications about overdue issues.

The periodicity of the repeating messages and the recipients settings are configured separately for each project or with templates.
The regular notifications schedule is set on the **Periodic tasks schedule** tab located on the Plugin Settings page.

One has to initialize the periodic tasks before the plugin's first run.

To do this, click "Initialize periodic tasks" in the "Schedule periodic tasks" tab in the plugin settings.

You can also set periodic notifications schedule convenient for you.

Schedule is set using the cron syntax.

# Setting the module within the project

Select the Intouch module in the project settings on the "Modules" tab.
As a result, the "Intouch" tab will appear in the Settings.

This tab includes three sections:

* Instant notifications when changing the issue status/priority
* Periodic notifications
* Assigner groups

## Instant notifications when changing the issue status/priority

This section allows you to set instant notifications for the following recipients:

* Author
* Assigner
* Task watchers
* Telegram groups

**Important note: The Telegram user should issue the `/start` command to recieve messages.**

## Periodic notifications

### General settings

The intervals of Periodic Notifications for different priority types are specified in General Settings.

### In work / Feedback

These tabs contain recipients of the Periodic Notifications with the "In work" and "Feedback" statuses.

### Unassigned / Assigned to the group

This tab contains recipients of the Periodic Notifications that are:

* not assigned to anyone
* assigned to the group

### Overdue / Without a due date

This tab contains recipients of the Periodic Notifications that are:

* overdue
* with unspecified due date

# FAQ
## Why does not the bot send messages to a group chat?

Perhaps you have not initialized **Periodic tasks schedule**.

In plugin settings go to the **Periodic tasks schedule** tab and click **Initialize periodic tasks**.


# Author of the Plugin

The plugin is designed by [Southbridge](https://southbridge.io)
