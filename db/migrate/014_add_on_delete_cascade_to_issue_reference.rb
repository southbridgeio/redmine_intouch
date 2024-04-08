class AddOnDeleteCascadeToIssueReference < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[[Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join('.')]
  def change
    remove_foreign_key :intouch_telegram_chat_subscriptions, :issues
    add_foreign_key :intouch_telegram_chat_subscriptions, :issues, column: :issue_id, on_delete: :cascade
  end
end
