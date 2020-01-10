module Intouch::Preview
  class KeyboardMarkup < Telegram::Bot::Types::InlineKeyboardMarkup
    def self.build_hash(issue_id, journal_id)
      Intouch.telegram_preview? ? { reply_markup: Intouch::Preview::KeyboardMarkup.new(issue_id, journal_id) } : {}
    end

    def initialize(issue_id, journal_id)
      keyboard = [
          [
              Telegram::Bot::Types::InlineKeyboardButton.new(text: I18n.t('label_preview'),
                                                             callback_data: { type: 'issue_preview', issue_id: issue_id, journal_id: journal_id }.to_json)
          ]
      ]

      super(inline_keyboard: keyboard)
    end
  end
end
