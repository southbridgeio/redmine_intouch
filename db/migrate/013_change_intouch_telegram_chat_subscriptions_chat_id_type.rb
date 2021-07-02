class ChangeIntouchTelegramChatSubscriptionsChatIdType < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[[Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join('.')]
  def change
    change_column :intouch_telegram_chat_subscriptions, :chat_id, :bigint
  end
end
