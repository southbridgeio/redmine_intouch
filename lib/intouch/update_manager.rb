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
      @handlers[update.class].each { |handler| handler.call(update) }
    end
  end
end
