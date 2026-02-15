# frozen_string_literal: true

RSpec.describe StrongSchema::TableExtension do
  let(:table_class) do
    Class.new(ActiveRecord::ConnectionAdapters::Table) do
      prepend StrongSchema::TableExtension
    end
  end

  let(:base) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }
  let(:table) { table_class.new("accounts", base) }

  before { StrongSchema.reset_ignores! }
  after { StrongSchema.reset_ignores! }

  describe "OPERATION_MAP" do
    subject(:map) { described_class::OPERATION_MAP }

    it "maps Table methods to migration-level methods" do
      expect(map).to include(
        column: :add_column,
        remove: :remove_column,
        rename: :rename_column,
        change: :change_column,
        change_default: :change_column_default,
        change_null: :change_column_null,
        index: :add_index,
        remove_index: :remove_index,
        remove_timestamps: :remove_timestamps,
        references: :add_reference,
        belongs_to: :add_reference,
        remove_references: :remove_reference,
        remove_belongs_to: :remove_reference,
        foreign_key: :add_foreign_key,
        check_constraint: :add_check_constraint
      )
    end

    it "is frozen" do
      expect(map).to be_frozen
    end
  end

  describe "operation interception" do
    let(:checker) { instance_double(StrongMigrations::Checker) }

    before do
      allow(StrongMigrations::Checker).to receive(:new)
        .with(described_class::MigrationProxy.instance)
        .and_return(checker)
      allow(checker).to receive(:direction=)
    end

    context "when not ignored and Checker blocks" do
      before do
        allow(checker).to receive(:perform).and_raise(
          StrongMigrations::UnsafeMigration, "Unsafe operation"
        )
      end

      it "raises UnsafeMigration for remove" do
        expect { table.remove(:status) }.to raise_error(StrongMigrations::UnsafeMigration)
      end

      it "raises UnsafeMigration for rename" do
        expect { table.rename(:old_name, :new_name) }.to raise_error(StrongMigrations::UnsafeMigration)
      end

      it "raises UnsafeMigration for change" do
        expect { table.change(:name, :text) }.to raise_error(StrongMigrations::UnsafeMigration)
      end
    end

    context "when not ignored and Checker allows" do
      before do
        allow(checker).to receive(:perform).and_yield
      end

      it "calls super (delegates to @base)" do
        allow(base).to receive(:add_column)
        expect { table.column(:name, :string) }.not_to raise_error
        expect(base).to have_received(:add_column).with("accounts", :name, :string)
      end
    end

    context "when ignored" do
      it "skips Checker and calls super for remove" do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "accounts" && args[1].to_s == "status"
        end
        allow(base).to receive(:remove_columns)
        expect(StrongMigrations::Checker).not_to receive(:new)
        expect { table.remove(:status) }.not_to raise_error
      end

      it "skips Checker and calls super for rename" do
        StrongSchema.add_ignore do |method, args|
          method == :rename_column && args[0].to_s == "accounts"
        end
        allow(base).to receive(:rename_column)
        expect(StrongMigrations::Checker).not_to receive(:new)
        expect { table.rename(:old_name, :new_name) }.not_to raise_error
      end

      it "does not skip non-matching operations" do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "other_table"
        end
        allow(checker).to receive(:perform).and_raise(
          StrongMigrations::UnsafeMigration, "Unsafe"
        )
        expect { table.remove(:status) }.to raise_error(StrongMigrations::UnsafeMigration)
      end
    end
  end

  describe "MigrationProxy" do
    subject(:proxy) { described_class::MigrationProxy.instance }

    it "is a singleton" do
      expect(proxy).to equal(described_class::MigrationProxy.instance)
    end

    it "returns false for reverting?" do
      expect(proxy.reverting?).to be false
    end

    it "returns nil for version" do
      expect(proxy.version).to be_nil
    end

    it "delegates connection to ActiveRecord::Base" do
      mock_connection = instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      allow(ActiveRecord::Base).to receive(:connection).and_return(mock_connection)
      expect(proxy.connection).to eq(mock_connection)
    end

    it "raises UnsafeMigration on stop!" do
      expect { proxy.stop!("test message") }.to raise_error(
        StrongMigrations::UnsafeMigration, /test message/
      )
    end
  end
end
