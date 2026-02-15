# frozen_string_literal: true

require "strong_migrations"

require_relative "strong_schema/version"
require_relative "strong_schema/configuration"
require_relative "strong_schema/schema_extension"

module StrongSchema
  class Error < StandardError; end
  class UnsafeMigration < Error; end

  class << self
    # @rbs!
    #   @setup_done: bool?
    #   @configuration: Configuration

    attr_writer :configuration #: Configuration

    #:  () -> Configuration
    def configuration
      @configuration ||= Configuration.new
    end

    #:  () { (Configuration) -> void } -> void
    def configure
      yield(configuration)
    end

    #:  () -> void
    def reset_configuration!
      @configuration = Configuration.new
    end

    #:  () -> void
    def setup
      return if @setup_done

      ActiveRecord::Schema.prepend(SchemaExtension)
      ActiveRecord::Schema::Definition.prepend(SchemaExtension) if defined?(ActiveRecord::Schema::Definition)

      @setup_done = true
    end

    # Temporarily enable checks for the duration of the block.
    # Useful when `enabled` defaults to false and you want to
    # activate checks only during specific operations (e.g., Ridgepole apply).
    #
    #   StrongSchema.with_check do
    #     system("ridgepole", "--apply", "-c", "config.yml")
    #   end
    #
    #:  () { () -> void } -> void
    def with_check
      previous = configuration.enabled
      configuration.enabled = true
      yield
    ensure
      configuration.enabled = previous
    end

    #:  (bool) -> void
    def install_boot_hook(rails_railtie_defined = defined?(Rails::Railtie))
      if rails_railtie_defined
        require_relative "strong_schema/railtie"
      else
        ActiveSupport.on_load(:active_record) do
          StrongSchema.setup
        end
      end
    end
  end
end

# Setup when ActiveRecord is loaded.
# In Rails, the Railtie handles this. In non-Rails environments (e.g., Ridgepole),
# ActiveSupport.on_load fires when ActiveRecord::Base is defined.
StrongSchema.install_boot_hook
