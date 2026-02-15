# frozen_string_literal: true

require "strong_migrations"

require_relative "strong_schema/version"
require_relative "strong_schema/schema_extension"

module StrongSchema
  class << self
    # @rbs!
    #   @setup_done: bool?

    #:  () -> void
    def setup
      return if @setup_done

      ActiveRecord::Schema.prepend(SchemaExtension)
      ActiveRecord::Schema::Definition.prepend(SchemaExtension) if defined?(ActiveRecord::Schema::Definition)

      @setup_done = true
    end

    #:  () -> void
    def install_boot_hook
      if defined?(Rails::Railtie)
        require_relative "strong_schema/railtie"
      elsif defined?(ActiveRecord::Base)
        setup
      else
        ActiveSupport.on_load(:active_record) { StrongSchema.setup }
      end
    end
  end
end

StrongSchema.install_boot_hook
