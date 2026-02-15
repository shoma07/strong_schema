# frozen_string_literal: true

RSpec.describe StrongSchema::IgnoreChecks do
  let(:test_module) do
    Module.new do
      extend StrongSchema::IgnoreChecks
    end
  end

  before do
    StrongSchema.reset_ignores!
  end

  after do
    StrongSchema.reset_ignores!
  end

  describe ".add_ignore" do
    it "adds an ignore check block" do
      expect do
        StrongSchema.add_ignore { |method, _args| method == :remove_column }
      end.to change { StrongSchema.ignore_checks.size }.by(1)
    end

    it "can add multiple ignore checks" do
      StrongSchema.add_ignore { |method, _args| method == :remove_column }
      StrongSchema.add_ignore { |method, _args| method == :add_column }

      expect(StrongSchema.ignore_checks.size).to eq(2)
    end
  end

  describe ".should_ignore?" do
    context "when no ignore checks are registered" do
      it "returns false" do
        expect(StrongSchema.should_ignore?(:remove_column, %i[users email])).to be false
      end
    end

    context "when ignore checks are registered" do
      before do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "users" && args[1].to_s == "email"
        end
      end

      it "returns true when the check matches" do
        expect(StrongSchema.should_ignore?(:remove_column, %i[users email])).to be true
      end

      it "returns false when the method does not match" do
        expect(StrongSchema.should_ignore?(:add_column, %i[users email])).to be false
      end

      it "returns false when the args do not match" do
        expect(StrongSchema.should_ignore?(:remove_column, %i[users name])).to be false
      end
    end

    context "with multiple ignore checks" do
      before do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "users"
        end

        StrongSchema.add_ignore do |method, args|
          method == :add_column && args[0].to_s == "posts" && args[1].to_s == "settings"
        end
      end

      it "returns true when any check matches" do
        expect(StrongSchema.should_ignore?(:remove_column, %i[users email])).to be true
        expect(StrongSchema.should_ignore?(:add_column, %i[posts settings json])).to be true
      end

      it "returns false when no checks match" do
        expect(StrongSchema.should_ignore?(:remove_index, %i[users email_idx])).to be false
      end
    end

    context "with complex matching conditions" do
      before do
        StrongSchema.add_ignore do |method, args|
          method == :add_column &&
            args[0].to_s == "posts" &&
            args[1].to_s == "settings" &&
            args[2] == :json &&
            args[3]&.dig(:default) == {}
        end
      end

      it "matches exact args including options hash" do
        expect(StrongSchema.should_ignore?(:add_column, [:posts, :settings, :json, { default: {} }])).to be true
      end

      it "does not match when options differ" do
        expect(StrongSchema.should_ignore?(:add_column, [:posts, :settings, :json, { default: nil }])).to be false
      end
    end

    context "with change_table operations" do
      before do
        StrongSchema.add_ignore do |method, args|
          method == :remove_column && args[0].to_s == "accounts" && args[1].to_s == "status"
        end
      end

      it "can ignore remove_column inside change_table blocks" do
        expect(StrongSchema.should_ignore?(:remove_column, %w[accounts status])).to be true
      end
    end
  end

  describe ".reset_ignores!" do
    it "clears all ignore checks" do
      StrongSchema.add_ignore { |method, _args| method == :remove_column }
      StrongSchema.add_ignore { |method, _args| method == :add_column }

      expect do
        StrongSchema.reset_ignores!
      end.to change { StrongSchema.ignore_checks.size }.to(0)
    end
  end
end
