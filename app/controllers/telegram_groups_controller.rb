class TelegramGroupsController < ApplicationController
  ALLOWED_SOURCE_TYPES = %w[Project SettingsTemplate].freeze

  layout 'admin'

  before_action :require_admin

  def index
    @telegram_group_chats =
      if params[:q].present?
        TelegramGroupChat.where('LOWER(title) LIKE ?', "%#{params[:q].downcase}%")
      else
        TelegramGroupChat.none
      end

    results = { results: @telegram_group_chats.map { |chat| { id: chat.id, text: chat.title } } }

    respond_to do |format|
      format.json { render json: results }
    end
  end

  def show
    @telegram_group = TelegramGroupChat.find(params[:id])
    @priorities = IssuePriority.order(:position)
    @statuses = IssueStatus.order(:position)

    unless params[:source_type].in?(ALLOWED_SOURCE_TYPES)
      render_404
      return
    end

    source_class = params[:source_type].safe_constantize

    @settings_source = source_class.find_by(id: params[:source_id]) || source_class.new

    respond_to do |format|
      format.js
    end
  end

  def destroy
    TelegramGroupChat.find(params[:id]).destroy
    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'telegram'
  rescue
    flash[:error] = l(:error_unable_delete_telegram_group)
    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'telegram'
  end
end
