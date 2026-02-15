# frozen_string_literal: true

module StrongSchema
  module SchemaExtension
    # Intercepts schema definition methods and runs Strong Migrations safety checks.
    #
    # Uses `self` (the ActiveRecord::Schema instance) as the migration object for
    # StrongMigrations::Checker. Since ActiveRecord::Schema inherits from
    # ActiveRecord::Migration, it already provides the full interface the Checker
    # expects: connection, version, reverting?, say, stop!, reversible, etc.
    #
    #:  (Symbol, *untyped) -> untyped
    def method_missing(method, *args)
      return super unless StrongSchema.configuration.enabled

      checker = StrongMigrations::Checker.new(self)
      checker.direction = :up

      catch(:safe) do
        checker.perform(method, *args) do
          super
        end
      end
    rescue StrongMigrations::UnsafeMigration => e
      handle_unsafe_migration(e)
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

    private

    #:  (StrongMigrations::UnsafeMigration) -> void
    def handle_unsafe_migration(error)
      raise StrongSchema::UnsafeMigration, error.message if StrongSchema.configuration.raise_on_unsafe

      log_warning(error.message)
    end

    #:  (String) -> void
    def log_warning(message)
      logger = StrongSchema.configuration.logger
      unless logger
        require "logger"
        logger = Logger.new($stdout)
      end
      logger.warn(message)
    end
  end
end
