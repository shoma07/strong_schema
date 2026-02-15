# frozen_string_literal: true

module StrongSchema
  class Railtie < Rails::Railtie
    initializer "strong_schema.configure" do
      ActiveSupport.on_load(:active_record) do
        StrongSchema.setup
      end
    end
  end
end
