# frozen_string_literal: true

module StrongSchema
  module TableExtension
    OPERATION_MAP = {
      column: :add_column,
      index: :add_index,
      change: :change_column,
      change_default: :change_column_default,
      change_null: :change_column_null,
      remove: :remove_column,
      remove_index: :remove_index,
      remove_timestamps: :remove_timestamps,
      rename: :rename_column,
      references: :add_reference,
      belongs_to: :add_reference,
      remove_references: :remove_reference,
      remove_belongs_to: :remove_reference,
      foreign_key: :add_foreign_key,
      check_constraint: :add_check_constraint
    }.freeze #: Hash[Symbol, Symbol]
    public_constant :OPERATION_MAP

    OPERATION_MAP.each do |table_method, migration_method|
      define_method(table_method) do |*args, **kwargs, &block|
        return super(*args, **kwargs, &block) if StrongSchema.should_ignore?(migration_method, [@name, *args])

        catch(:safe) do
          checker = StrongMigrations::Checker.new(MigrationProxy.instance).tap { |c| c.direction = :up }
          checker.perform(migration_method, @name, *args, **kwargs) { super(*args, **kwargs, &block) }
        end
      end
    end

    class MigrationProxy
      include Singleton

      #:  () -> false
      def reverting?
        false
      end

      #:  () -> nil
      def version; end

      #:  () -> ActiveRecord::ConnectionAdapters::AbstractAdapter
      def connection
        ActiveRecord::Base.connection
      end

      #:  (String, ?header: String) -> void
      def stop!(message, header: "Custom check")
        raise StrongMigrations::UnsafeMigration, "\n=== #{header} #strong_migrations ===\n\n#{message}\n"
      end
    end
  end
end
