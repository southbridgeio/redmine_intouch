module Intouch::Regular
  class RecipientsList
    def initialize(issue:, protocol:, state:)
      @issue = issue
      @protocol = protocol
      @state = state
    end

    attr_reader :issue, :protocol, :state

    def call
      return [] unless recipient_ids.present?

      users = User.where(id: recipient_ids).status(User::STATUS_ACTIVE)
      customer = Intouch.helpdesk_contact(@issue) if @protocol == 'email' && @issue.project.module_enabled?(:contacts)
      users + [customer].compact - [User.anonymous]
    end

    def recipient_ids
      return @recipient_ids if defined?(@recipient_ids)

      return unless state_settings.present?

      @recipient_ids = potential_recipient_ids & assigner_ids
    end

    def potential_recipient_ids
      state_settings.map do |key, value|
        case key
          when 'author'
            issue.author_id
          when 'assigned_to'
            issue.assigned_to_id if issue.assigned_to.class == User
          when 'watchers'
            issue.watchers.pluck(:user_id)
          when 'user_groups'
            Group.where(id: value).map(&:user_ids).flatten if value.present?
        end
      end.flatten.uniq
    end

    def assigner_ids
      @assigner_ids ||= project.assigner_ids
    end

    def state_settings
      return @state_settings if defined?(@state_settings)

      return nil unless active_protocol_settings.present?

      @state_settings = active_protocol_settings[state]
    end

    def active_protocol_settings
      @active_protocol_settings ||= project.send("active_#{protocol}_settings")
    end

    def project
      @project ||= issue.project
    end
  end
end