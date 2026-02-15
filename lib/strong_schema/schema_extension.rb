# frozen_string_literal: true

module StrongSchema
  module SchemaExtension
    #:  (Symbol, *untyped) -> untyped
    def method_missing(method, *args)
      return super if method == :change_table || StrongSchema.should_ignore?(method, args)

      catch(:safe) do
        StrongMigrations::Checker.new(self).tap { |c| c.direction = :up }.perform(method, *args) do
          super
        end
      end
    end

    begin
      ruby2_keywords(:method_missing)
    rescue NameError
      # ruby2_keywords is unavailable in some Ruby versions.
    end
  end
end
