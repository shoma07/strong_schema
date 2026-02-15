# frozen_string_literal: true

module StrongSchema
  module SchemaExtension
    #:  (Symbol, *untyped) -> untyped
    def method_missing(method, *args)
      checker = StrongMigrations::Checker.new(self)
      checker.direction = :up

      catch(:safe) do
        checker.perform(method, *args) do
          super
        end
      end
    end

    begin
      ruby2_keywords(:method_missing)
    rescue NameError
      # ruby2_keywords is unavailable in some Ruby versions.
    end

    #:  (Symbol, ?bool) -> bool
    def respond_to_missing?(method, include_private = false)
      super
    end

    #:  () { () -> void } -> void
    def safety_assured(&block)
      StrongMigrations::Checker.safety_assured(&block)
    end
  end
end
