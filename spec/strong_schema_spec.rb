# frozen_string_literal: true

RSpec.describe StrongSchema do
  it "has a version number" do
    expect(StrongSchema::VERSION).not_to be_nil
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(StrongSchema::Configuration)
    end

    it "has default values" do
      config = described_class.configuration
      expect(config.enabled).to be true
      expect(config.raise_on_unsafe).to be true
    end
  end

  describe ".configure" do
    after do
      described_class.reset_configuration!
    end

    it "allows configuration" do
      described_class.configure do |config|
        config.enabled = false
        config.raise_on_unsafe = false
      end

      expect(described_class.configuration.enabled).to be false
      expect(described_class.configuration.raise_on_unsafe).to be false
    end
  end

  describe ".with_check" do
    after do
      described_class.reset_configuration!
    end

    it "temporarily enables checks for the duration of the block" do
      described_class.configure { |c| c.enabled = false }
      expect(described_class.configuration.enabled).to be false

      described_class.with_check do
        expect(described_class.configuration.enabled).to be true
      end

      expect(described_class.configuration.enabled).to be false
    end

    it "restores the original state even if the block raises" do
      described_class.configure { |c| c.enabled = false }

      begin
        described_class.with_check { raise "boom" }
      rescue RuntimeError
        nil
      end

      expect(described_class.configuration.enabled).to be false
    end

    it "is a no-op wrapper when already enabled" do
      described_class.configure { |c| c.enabled = true }

      described_class.with_check do
        expect(described_class.configuration.enabled).to be true
      end

      expect(described_class.configuration.enabled).to be true
    end
  end

  describe ".setup" do
    before do
      described_class.instance_variable_set(:@setup_done, nil)
    end

    after do
      described_class.instance_variable_set(:@setup_done, nil)
    end

    it "prepends SchemaExtension to ActiveRecord::Schema" do
      described_class.setup
      expect(ActiveRecord::Schema.ancestors).to include(StrongSchema::SchemaExtension)
    end

    it "prepends SchemaExtension to ActiveRecord::Schema::Definition" do
      described_class.setup
      expect(ActiveRecord::Schema::Definition.ancestors).to include(StrongSchema::SchemaExtension)
    end

    it "is idempotent (does not duplicate ancestors)" do
      described_class.setup
      ancestors_count = ActiveRecord::Schema.ancestors.count { |a| a == StrongSchema::SchemaExtension }

      described_class.setup
      new_ancestors_count = ActiveRecord::Schema.ancestors.count { |a| a == StrongSchema::SchemaExtension }

      expect(ancestors_count).to eq(new_ancestors_count)
    end

    it "skips Schema::Definition prepend when definition constant is missing" do
      if defined?(ActiveRecord::Schema::Definition)
        definition_const = ActiveRecord::Schema.send(:remove_const, :Definition)

        begin
          expect { described_class.setup }.not_to raise_error
        ensure
          ActiveRecord::Schema.const_set(:Definition, definition_const)
        end
      end
    end
  end

  describe "error hierarchy" do
    it "StrongSchema::Error inherits from StandardError" do
      expect(StrongSchema::Error).to be < StandardError
    end

    it "StrongSchema::UnsafeMigration inherits from StrongSchema::Error" do
      expect(StrongSchema::UnsafeMigration).to be < StrongSchema::Error
    end
  end

  describe "bool hook" do
    let(:root) { File.expand_path("..", __dir__) }
    let(:version_file) { File.join(root, "lib", "strong_schema", "version.rb") }

    it "registers ActiveRecord on_load hook when Rails::Railtie is not defined" do
      allow(described_class).to receive(:setup)
      expect(ActiveSupport).to receive(:on_load).with(:active_record).and_yield

      described_class.install_boot_hook(false)

      expect(described_class).to have_received(:setup)
    end

    it "loads railtie integration when Rails::Railtie is defined" do
      stub_const("Rails", Module.new)
      railtie_base = Class.new do
        def self.initializer(_name)
          yield
        end
      end
      Rails.const_set(:Railtie, railtie_base)

      expect(ActiveSupport).to receive(:on_load).with(:active_record).and_yield

      described_class.install_boot_hook(true)

      expect(described_class.const_defined?(:Railtie)).to be true
    end

    it "loads version constants" do
      described_class.send(:remove_const, :VERSION) if described_class.const_defined?(:VERSION)
      load version_file

      expect(described_class::VERSION).not_to be_nil
    end
  end
end
