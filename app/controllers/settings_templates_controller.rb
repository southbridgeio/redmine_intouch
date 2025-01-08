class SettingsTemplatesController < ApplicationController

  layout 'admin'

  before_action :require_admin

  accept_api_auth :index

  def index
    @settings_templates = SettingsTemplate.order(:name)

    respond_to do |format|
      format.api
      format.html { render action: 'index', layout: false if request.xhr? }
    end
  end

  def new
    @settings_template = SettingsTemplate.new
    if params[:copy_from]
      begin
        @copy_from = SettingsTemplate.find(params[:copy_from])

        @settings_template.copy_from(@copy_from)
      rescue ActiveRecord::RecordNotFound
        render_404
        return
      end
    end
  end

  def create
    @settings_template = SettingsTemplate.new(settings_template_params)
    @settings_template.intouch_settings = params[:intouch_settings].to_unsafe_h
    if @settings_template.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to controller: 'settings_templates', action: 'edit', id: @settings_template
    else
      render action: 'new'
    end
  end

  def edit
    @settings_template = SettingsTemplate.find(params[:id])
  end

  def update
    @settings_template = SettingsTemplate.find(params[:id])
    @settings_template.intouch_settings = params[:intouch_settings].to_unsafe_h
    if @settings_template.update_attribute(:name, settings_template_params[:name])
      flash[:notice] = l(:notice_successful_update)
      redirect_to controller: 'settings_templates', action: 'edit', id: @settings_template
    else
      render action: 'edit'
    end
  end

  def destroy
    SettingsTemplate.find(params[:id]).destroy
    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'settings_templates'
  rescue
    flash[:error] = l(:error_unable_delete_settings_template)
    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'settings_templates'
  end

  private

  def settings_template_params
    params.require(:settings_template).permit(:name)
  end
end
