# frozen_string_literal: true

RSpec.describe StrongSchema::SchemaExtension do
  let(:schema_class) do
    Class.new(ActiveRecord::Migration::Current) do
      prepend StrongSchema::SchemaExtension
    end
  end

  let(:schema) { schema_class.new }

  before do
    StrongSchema.reset_ignores!
  end

  after do
    StrongSchema.reset_ignores!
  end

  describe "checked methods" do
    let(:checker) { instance_double(StrongMigrations::Checker) }

    before do
      allow(StrongMigrations::Checker).to receive(:new).and_return(checker)
      allow(checker).to receive(:direction=)
    end

    context "when checker raises UnsafeMigration" do
      before do
        allow(checker).to receive(:perform).and_raise(
          StrongMigrations::UnsafeMigration, "Active Record caches attributes"
        )
      end

      it "raises StrongMigrations::UnsafeMigration" do
        expect do
          schema.remove_column(:accounts, :status)
        end.to raise_error(StrongMigrations::UnsafeMigration, /Active Record caches attributes/)
      end
    end

    context "when checker does not raise" do
      before do
        allow(checker).to receive(:perform).and_yield
      end

      it "allows the operation" do
        # super's method_missing will eventually raise without a real DB
        expect { schema.add_column(:accounts, :name, :string) }.to raise_error(StandardError)
      end
    end
  end

  describe "ignore checks" do
    let(:fresh_schema_class) do
      # Use a plain class (not inheriting Migration) to isolate SchemaExtension's logic
      klass = Class.new do
        prepend StrongSchema::SchemaExtension

        def method_missing(_method, *_args, **_kwargs, &_block)
          :called_super
        end
      end
      klass
    end

    let(:fresh_schema) { fresh_schema_class.new }

    context "when operation is ignored" do
      it "skips safety checks and calls super" do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "accounts" && args[1].to_s == "status"
        end

        expect(StrongMigrations::Checker).not_to receive(:new)
        expect(fresh_schema.remove_column(:accounts, :status)).to eq(:called_super)
      end

      it "does not skip checks for non-matching operations" do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "accounts" && args[1].to_s == "status"
        end

        checker = instance_double(StrongMigrations::Checker)
        allow(StrongMigrations::Checker).to receive(:new).and_return(checker)
        allow(checker).to receive(:direction=)
        allow(checker).to receive(:perform).and_raise(
          StrongMigrations::UnsafeMigration, "Active Record caches attributes"
        )

        expect do
          fresh_schema.remove_column(:accounts, :other_column)
        end.to raise_error(StrongMigrations::UnsafeMigration)
      end

      it "always skips change_table (handled by TableExtension)" do
        expect(StrongMigrations::Checker).not_to receive(:new)
        expect(fresh_schema.change_table(:accounts, bulk: true)).to eq(:called_super)
      end
    end
  end
end
