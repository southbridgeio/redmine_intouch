class IntouchMailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :issues
  helper :custom_fields

  include Redmine::I18n

  default from: Setting.mail_from

  def self.default_url_options
    ::Mailer.default_url_options
  end

  def reminder_email(user, issue)
    Intouch.set_locale
    @user = user
    @issue = issue

    mail to: @user.mail, subject: @issue.subject
  end

  def overdue_issues_email(user_id, issue_ids)
    Intouch.set_locale
    @user = User.find user_id
    @issues = Issue.open.where(id: issue_ids).includes(:project)

    @overdue_issues = @issues.where('due_date < ?', Date.today).order(:due_date)
    @without_due_date_issues = @issues.where(due_date: nil).where('created_on < ?', 1.day.ago).order(:created_on)

    @unassigned_issues = @issues.where(assigned_to_id: nil).order(:created_on)
    @group_assigned_issues = @issues.joins(:assigned_to).where(users: { type: 'Group' }).order(:created_on)

    mail to: @user.mail,
         subject: t('intouch.mailer.subject', date: format_date(Date.today))
  end
end
