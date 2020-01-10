module Intouch
  class CommandHandler
    extend ServiceInitializer

    def initialize(message)
      @message = message
    end

    def call
      Intouch::TelegramBot.new(message).call
    end

    private

    attr_reader :message
  end
end
