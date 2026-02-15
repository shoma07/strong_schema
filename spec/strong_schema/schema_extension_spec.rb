# frozen_string_literal: true

RSpec.describe StrongSchema::SchemaExtension do
  let(:schema_class) do
    Class.new do
      prepend StrongSchema::SchemaExtension

      attr_reader :last_called_method, :last_called_args

      def method_missing(method, *args)
        @last_called_method = method
        @last_called_args = args
      end

      def respond_to_missing?(method, include_private = false)
        super
      end
    end
  end

  let(:schema) { schema_class.new }

  before do
    StrongSchema.configure do |config|
      config.enabled = true
      config.raise_on_unsafe = true
    end
  end

  after do
    StrongSchema.reset_configuration!
  end

  describe "#method_missing" do
    context "when StrongSchema is disabled" do
      before do
        StrongSchema.configure { |c| c.enabled = false }
      end

      it "bypasses safety checks and calls super directly" do
        expect(StrongMigrations::Checker).not_to receive(:new)
        schema.add_column(:users, :email, :string)
        expect(schema.last_called_method).to eq(:add_column)
        expect(schema.last_called_args).to eq(%i[users email string])
      end
    end

    context "when StrongSchema is enabled" do
      let(:checker) { instance_double(StrongMigrations::Checker) }

      before do
        allow(StrongMigrations::Checker).to receive(:new).with(schema).and_return(checker)
        allow(checker).to receive(:direction=)
      end

      it "creates a Checker with self and performs checks" do
        allow(checker).to receive(:perform).with(:add_column, :users, :email, :string).and_yield

        schema.add_column(:users, :email, :string)

        expect(StrongMigrations::Checker).to have_received(:new).with(schema)
        expect(checker).to have_received(:direction=).with(:up)
        expect(schema.last_called_method).to eq(:add_column)
      end

      it "raises StrongSchema::UnsafeMigration on unsafe operations" do
        allow(checker).to receive(:perform).and_raise(
          StrongMigrations::UnsafeMigration, "unsafe operation detected"
        )

        expect do
          schema.remove_column(:users, :old_column)
        end.to raise_error(StrongSchema::UnsafeMigration, /unsafe operation detected/)
      end

      context "when raise_on_unsafe is false" do
        before do
          StrongSchema.configure { |c| c.raise_on_unsafe = false }
        end

        it "logs a warning using the configured logger" do
          allow(checker).to receive(:perform).and_raise(
            StrongMigrations::UnsafeMigration, "unsafe operation detected"
          )

          logger = instance_double(Logger)
          StrongSchema.configure { |c| c.logger = logger }
          allow(logger).to receive(:warn)

          expect do
            schema.remove_column(:users, :old_column)
          end.not_to raise_error

          expect(logger).to have_received(:warn).with(/unsafe operation detected/)
        end

        it "falls back to a default Logger when none configured" do
          allow(checker).to receive(:perform).and_raise(
            StrongMigrations::UnsafeMigration, "unsafe operation detected"
          )

          default_logger = instance_double(Logger)
          allow(Logger).to receive(:new).with($stdout).and_return(default_logger)
          allow(default_logger).to receive(:warn)

          schema.remove_column(:users, :old_column)

          expect(default_logger).to have_received(:warn).with(/unsafe operation detected/)
        end
      end

      it "handles :safe throw from safe_by_default" do
        allow(checker).to receive(:perform) { throw :safe }

        expect { schema.add_index(:users, :email) }.not_to raise_error
        expect(schema.last_called_method).to be_nil
      end
    end
  end

  describe "#safety_assured" do
    it "delegates to StrongMigrations::Checker.safety_assured" do
      expect(StrongMigrations::Checker).to receive(:safety_assured).and_yield

      result = schema.safety_assured { :safe_result }
      expect(result).to eq(:safe_result)
    end
  end

  describe "#respond_to_missing?" do
    it "falls back to super" do
      expect(schema.send(:respond_to_missing?, :non_existing_method, false)).to be false
    end
  end
end
