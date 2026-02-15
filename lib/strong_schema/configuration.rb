# frozen_string_literal: true

module StrongSchema
  class Configuration
    attr_accessor :enabled #: bool
    attr_accessor :raise_on_unsafe #: bool
    attr_accessor :logger #: Logger?

    #:  () -> void
    def initialize
      @enabled = true
      @raise_on_unsafe = true
      @logger = nil
    end
  end
end
