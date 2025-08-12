class Intouch::Protocols::Telegram
  class GroupUpdateCommand
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    def group?
      true
    end

    def allowed?(_user)
      true
    end

    def name
      'update'
    end

    def command?
      true
    end

    def description
      I18n.t('intouch.bot.group.help.update')
    end

    def call(action:, bot:)
      chat = TelegramGroupChat.where(tid: action.chat_id.abs).first_or_initialize(title: action.chat_title)
      chat.new_record? ? chat.save! : chat.update!(title: action.chat_title)
      bot.async.send_message(chat_id: action.chat_id, text: I18n.t('intouch.bot.group.update.message'))
    end
  end
end
