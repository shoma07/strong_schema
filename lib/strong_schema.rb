# frozen_string_literal: true

require "singleton"
require "strong_migrations"

require_relative "strong_schema/version"
require_relative "strong_schema/ignore_checks"
require_relative "strong_schema/schema_extension"
require_relative "strong_schema/table_extension"

module StrongSchema
  extend IgnoreChecks

  class << self
    # @rbs!
    #   @setup_done: bool?

    #:  () -> void
    def setup
      return if @setup_done

      ActiveRecord::Schema.prepend(SchemaExtension)
      ActiveRecord::ConnectionAdapters::Table.prepend(TableExtension)

      @setup_done = true
    end

    #:  () -> void
    def install_boot_hook
      if defined?(Rails::Railtie)
        require_relative "strong_schema/railtie"
      elsif defined?(ActiveRecord::Base)
        setup
      elsif defined?(ActiveSupport)
        ActiveSupport.on_load(:active_record) { StrongSchema.setup }
      end
    end
  end
end

StrongSchema.install_boot_hook
