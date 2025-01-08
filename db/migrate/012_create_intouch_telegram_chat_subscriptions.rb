class CreateIntouchTelegramChatSubscriptions < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[[Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join('.')]
  def change
    create_table :intouch_telegram_chat_subscriptions do |t|
      t.integer :chat_id, null: false
      t.belongs_to :issue, type: :integer, foreign_key: true, null: false
    end
  end
end
