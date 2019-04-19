# frozen_string_literal: true
module Intouch
  module ServiceInitializer
    def to_proc
      proc { |*args| call(*args) }
    end

    def call(*args)
      new(*args).call
    end
  end
end
