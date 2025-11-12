class TelegramUser < ApplicationRecord

  belongs_to :user

  def name
    if username.present?
      "#{first_name} #{last_name} @#{username}"
    else
      "#{first_name} #{last_name}"
    end
  end

  def activate!
    update(active: true) unless active?
  end

  def deactivate!
    update(active: false) if active?
  end
end
