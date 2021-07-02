class Intouch::Protocols::Telegram
  class NameUpdateCommand
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    def private?
      true
    end

    def allowed?(user)
      user.active?
    end

    def name
      'update'
    end

    def command?
      true
    end

    def description
      I18n.t('intouch.bot.private.help.update')
    end

    def call(action:, bot:)
      account = action.telegram_account || return

      account.update!(username: action.from.username,
                                first_name: action.from.first_name,
                                last_name: action.from.last_name)

      bot.async.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.private.update.message'))
    end
  end
end
