# frozen_string_literal: true

RSpec.describe StrongSchema::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.enabled).to be true
      expect(config.raise_on_unsafe).to be true
      expect(config.logger).to be_nil
    end
  end

  describe "attribute accessors" do
    it "allows setting enabled" do
      config.enabled = false
      expect(config.enabled).to be false
    end

    it "allows setting raise_on_unsafe" do
      config.raise_on_unsafe = false
      expect(config.raise_on_unsafe).to be false
    end

    it "allows setting logger" do
      logger = Logger.new($stdout)
      config.logger = logger
      expect(config.logger).to eq(logger)
    end
  end
end
