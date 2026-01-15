module Intouch
  class IssueDecorator < SimpleDelegator
    include Intouch::Support::IssueFormatable

    def initialize(issue, journal_id, protocol:)
      super(issue)
      @journal = journals.find_by(id: journal_id)
      @protocol = protocol
    end

    def journal
      @journal
    end

    def protocol
      @protocol
    end

    def updated_by
      @journal&.user
    end
  end
end
