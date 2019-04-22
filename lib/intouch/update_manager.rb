module Intouch
  class UpdateManager
    def initialize
      @handlers = {}
    end

    def on(update_type, &block)
      @handlers[update_type] ||= []
      @handlers[update_type] << block
    end

    def dispatch(update)
      @handlers.each { |type, handlers| handlers.each { |handler| handler.call(update) } if update.is_a?(type) }
    end
  end
end
