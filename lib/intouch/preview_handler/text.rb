class Intouch::PreviewHandler
  class Text
    include ApplicationHelper

    def self.normalize(issue)
      new(issue.description.presence || issue.journals.last&.notes.presence || issue.subject).normalized
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
