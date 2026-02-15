# frozen_string_literal: true

RSpec.describe StrongSchema::SchemaExtension do
  let(:schema_class) do
    Class.new(ActiveRecord::Migration::Current) do
      prepend StrongSchema::SchemaExtension
    end
  end

  let(:schema) { schema_class.new }

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
end
