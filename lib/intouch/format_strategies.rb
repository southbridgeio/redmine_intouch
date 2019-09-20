module Intouch
  module FormatStrategies
    class Markdown
      def bold(str)
        "*#{str}*"
      end

      def code(str)
        "`#{str}`"
      end
    end

    class Html
      def bold(str)
        "<b>#{str}</b>"
      end

      def code(str)
        "<code>#{str}</code>"
      end
    end

    MAPPING = {
      markdown: Markdown.new,
      html: Html.new
    }
    private_constant :MAPPING

    def self.[](key)
      MAPPING[key.to_sym]
    end
  end
end
