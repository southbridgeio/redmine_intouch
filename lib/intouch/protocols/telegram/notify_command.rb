class Intouch::Protocols::Telegram
  class NotifyCommand
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    def command?
      true
    end

    def private?
      true
    end

    def name
      'notify'
    end

    def description
      I18n.t('intouch.bot.private.help.notify')
    end

    def allowed?(user)
      user.active?
    end

    def call(action:, bot:)
      user = action.user
      command_arguments = action.command.drop(1).first

      (bot.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.subscription_failure')) && return) if [user, command_arguments].any?(&:blank?)

      if command_arguments == 'clear'
        IntouchSubscription.where(user_id: user.id).destroy_all
        bot.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.subscription_success'))
        return
      end

      project = Project.like(command_arguments).first

      (bot.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.subscription_failure')) && return) if project.blank?

      if IntouchSubscription.find_or_create_by(project_id: project.id, user_id: user.id).active?
        bot.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.subscription_success'))
      else
        bot.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.subscription_failure'))
      end
    end
  end
end