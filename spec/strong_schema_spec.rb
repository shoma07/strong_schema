# frozen_string_literal: true

RSpec.describe StrongSchema do
  it "has a version number" do
    expect(StrongSchema::VERSION).not_to be_nil
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

  describe "boot hook" do
    let(:root) { File.expand_path("..", __dir__) }
    let(:version_file) { File.join(root, "lib", "strong_schema", "version.rb") }

    context "when Rails::Railtie is not defined" do
      before do
        allow(described_class).to receive(:setup)
      end

      it "calls setup immediately when ActiveRecord::Base is defined" do
        described_class.install_boot_hook

        expect(described_class).to have_received(:setup)
      end

      it "registers ActiveRecord on_load hook when ActiveRecord::Base is not defined" do
        ar_base = ActiveRecord::Base
        ActiveRecord.send(:remove_const, :Base)

        expect(ActiveSupport).to receive(:on_load).with(:active_record)

        described_class.install_boot_hook
      ensure
        ActiveRecord.const_set(:Base, ar_base)
      end
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

      described_class.install_boot_hook

      expect(described_class.const_defined?(:Railtie)).to be true
    end

    it "loads version constants" do
      described_class.send(:remove_const, :VERSION) if described_class.const_defined?(:VERSION)
      load version_file

      expect(described_class::VERSION).not_to be_nil
    end
  end
end
