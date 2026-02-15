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

  describe "#respond_to_missing?" do
    before do
      allow(schema).to receive(:connection).and_return(double(respond_to?: false))
    end

    it "delegates to super" do
      result = schema.send(:respond_to_missing?, :some_undefined_method, false)
      expect(result).to be false
    end
  end

  describe "#safety_assured" do
    it "delegates to StrongMigrations::Checker.safety_assured" do
      expect(StrongMigrations::Checker).to receive(:safety_assured).and_yield

      result = schema.safety_assured { :safe_result }
      expect(result).to eq(:safe_result)
    end

    it "bypasses safety checks when wrapping unsafe operations" do
      checker = instance_double(StrongMigrations::Checker)
      allow(StrongMigrations::Checker).to receive(:new).and_return(checker)
      allow(checker).to receive(:direction=)

      allow(checker).to receive(:perform).and_yield

      expect { schema.safety_assured { schema.remove_column(:accounts, :status) } }.to(
        raise_error(StandardError) do |error|
          expect(error).not_to be_a(StrongMigrations::UnsafeMigration)
        end
      )
    end
  end
end
