class Intouch::PreviewHandler
  class Text
    include ApplicationHelper
    include ActionView::Helpers::SanitizeHelper

    def self.normalize(journal)
      issue = journal.issue
      new(journal.notes.presence || issue&.description.presence || issue&.subject || '').normalized
    end

    def initialize(raw_text)
      @raw_text = raw_text
    end

    def normalized
      sanitizer.sanitize(textilizable(raw_text)).truncate(200)
    end

    private

    attr_reader :raw_text

    def sanitizer
      Rails::Html::FullSanitizer.new
    end
  end
end
