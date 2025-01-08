class IntouchCronJobsController < ApplicationController

  layout 'admin'

  before_action :require_admin

  accept_api_auth :index

  def init
    hash = {
      'cron_feedback_regular_notification' => {
        'class' => 'CronFeedbackRegularNotification',
        'cron'  => '*/5 * * * *'
      },
      'cron_overdue_regular_notification' => {
        'class' => 'CronOverdueRegularNotification',
        'cron'  => '0 10 * * *'
      },
      'cron_unassigned_regular_notification' => {
        'class' => 'CronUnassignedRegularNotification',
        'cron'  => '*/15 * * * *'
      },
      'cron_working_regular_notification' => {
        'class' => 'CronWorkingRegularNotification',
        'cron'  => '*/5 * * * *'
      }
    }

    Sidekiq::Cron::Job.load_from_hash hash

    redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'sidekiq_cron_jobs'
  end

  def index
    @sidekiq_cron_jobs = Sidekiq::Cron::Job.all

    respond_to do |format|
      format.api
      format.html { render action: 'index', layout: false if request.xhr? }
    end
  end

  def edit
    @sidekiq_cron_job = Sidekiq::Cron::Job.find(params[:id])
  end

  def update
    @sidekiq_cron_job = Sidekiq::Cron::Job.find(params[:id])
    @sidekiq_cron_job.cron = params[:sidekiq_cron_job][:cron] if params[:sidekiq_cron_job]

    if @sidekiq_cron_job.valid?
      @sidekiq_cron_job.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'plugin', id: 'redmine_intouch', controller: 'settings', tab: 'sidekiq_cron_jobs'
    else
      render action: 'edit'
    end
  end
end
