# frozen_string_literal: true

module StrongSchema
  module IgnoreChecks
    #:  () { (Symbol, Array[untyped]) -> bool } -> void
    def add_ignore(&block)
      ignore_checks << block
    end

    #:  () -> Array[Proc]
    def ignore_checks
      @ignore_checks ||= []
    end

    #:  () -> void
    def reset_ignores!
      @ignore_checks = []
    end

    #:  (Symbol, Array[untyped]) -> bool
    def should_ignore?(method, args)
      ignore_checks.any? { |check| check.call(method, args) }
    end
  end
end
