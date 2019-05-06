module Intouch::Preview
  class KeyboardMarkup < Telegram::Bot::Types::InlineKeyboardMarkup
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
