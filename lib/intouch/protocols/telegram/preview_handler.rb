class Intouch::Protocols::Telegram
  class PreviewHandler
    include RedmineBots::Telegram::Bot::Handlers::HandlerBehaviour

    def match?(action)
      action.callback_query?
    end

    def private?
      true
    end

    def group?
      true
    end

    def allowed?(user)
      user.active?
    end

    def call(action:, **)
      Intouch::Preview::Handler.call(action.message)
    end
  end
end