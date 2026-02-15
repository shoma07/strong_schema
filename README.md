# Strong Schema

🛡️ Brings [Strong Migrations](https://github.com/ankane/strong_migrations) safety checks to declarative schema definitions using `ActiveRecord::Schema`.

Perfect for:
- [Ridgepole](https://github.com/ridgepole/ridgepole) users
- Direct `ActiveRecord::Schema` usage
- Rails `schema.rb` files
- Any tool using `ActiveRecord::Schema`

## Why Strong Schema?

`ActiveRecord::Schema` is commonly used for declarative schema management, but lacks the safety checks that migrations have. Strong Schema bridges this gap by integrating Strong Migrations' battle-tested checks into schema definitions.

## Features

- ✅ Detects dangerous operations in schema definitions
- ✅ Provides clear error messages and safer alternatives
- ✅ Supports PostgreSQL, MySQL, and MariaDB
- ✅ Works with Ridgepole, schema.rb, and direct ActiveRecord::Schema usage
- ✅ Zero configuration required (works out of the box)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'strong_schema'
```

And then execute:

```bash
bundle install
```

## Usage

### With Ridgepole

Once installed, Strong Schema automatically integrates with Ridgepole. When you run `ridgepole --apply`, unsafe operations in your Schemafile will be detected:

```ruby
# Schemafile
create_table "users", force: :cascade do |t|
  t.string "name"
  t.string "email"
  t.timestamps
end

# This will be flagged as unsafe!
add_column :users, :settings, :json, default: {}
```

When you try to apply this:

```bash
$ ridgepole -c config.yml --apply
```

You'll see:

```
=== Dangerous operation detected #strong_migrations ===

Adding a column with a non-null default blocks reads and writes...

In your schema definition, you can wrap the operation with safety_assured:

safety_assured do
  add_column(:users, :settings, :json, {:default=>{}})
end
```

### With Rails schema.rb

Strong Schema also works with Rails' `schema.rb`:

```ruby
# db/schema.rb
ActiveRecord::Schema.define(version: 2026_02_15_000000) do
  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.timestamps
  end

  # Unsafe operations are caught here too!
  safety_assured do
    remove_column :users, :old_column
  end
end
```

### Direct ActiveRecord::Schema Usage

Works in scripts, tests, or anywhere you use `ActiveRecord::Schema.define`:

```ruby
ActiveRecord::Schema.define do
  create_table :test_users, temporary: true do |t|
    t.string :name
  end
  
  # Safety checks apply here as well
  safety_assured do
    add_index :test_users, :name, algorithm: :concurrently
  end
end
```

### Bypassing Safety Checks

When you're certain an operation is safe, wrap it with `safety_assured`:

```ruby
# In your Schemafile, schema.rb, or Schema.define block
safety_assured do
  remove_column :users, :old_column
end
```

### Configuration

```ruby
# config/initializers/strong_schema.rb

StrongSchema.configure do |config|
  # Disable Strong Schema completely (default: true)
  config.enabled = false

  # Log warnings instead of raising errors (default: true)
  config.raise_on_unsafe = false

  # Custom logger (default: nil — falls back to Logger.new($stdout))
  config.logger = Rails.logger
end

# Strong Migrations configuration is independent — use its own API:
StrongMigrations.auto_analyze = true
StrongMigrations.target_postgresql_version = "13"
```

### Conditional Activation

By default, Strong Schema checks every `ActiveRecord::Schema` operation.
If you want checks **only during specific tasks** (e.g., Ridgepole), disable it globally and enable it per-task:

```ruby
# config/initializers/strong_schema.rb
StrongSchema.configure do |config|
  config.enabled = false
end
```

Then enable checks only where you need them:

```ruby
# lib/tasks/ridgepole.rake
namespace :ridgepole do
  desc "Apply schema with safety checks"
  task apply: :environment do
    StrongSchema.with_check do
      system("ridgepole", "--apply", "-c", "config/database.yml", "-E", Rails.env)
    end
  end
end
```

Or with a plain script:

```ruby
require "strong_schema"

StrongSchema.with_check do
  ActiveRecord::Schema.define do
    add_column :users, :email, :string, default: ""
  end
end
```

## How It Works

Strong Schema integrates by extending `ActiveRecord::Schema`, which is used by:
- Ridgepole to evaluate Schemafiles
- Rails to load `schema.rb`
- Any tool using declarative schema definitions

When dangerous operations are detected, it uses Strong Migrations' battle-tested checks to provide detailed guidance.

## Supported Checks

All [Strong Migrations checks](https://github.com/ankane/strong_migrations#checks) are supported:

- Removing columns
- Changing column types
- Renaming columns/tables
- Adding columns with defaults
- Adding indexes non-concurrently (Postgres)
- Adding foreign keys
- And many more...

## Use Cases

### 1. Ridgepole Schema Management

```ruby
# Schemafile with safety checks
create_table "posts" do |t|
  t.string "title"
  t.text "content"
end

# Safe concurrent index
add_index "posts", ["title"], algorithm: :concurrently
```

### 2. Rails Schema Loading

```ruby
# db/schema.rb - checked when loaded
ActiveRecord::Schema.define(version: 2026_02_15_000000) do
  # Your schema definitions with automatic safety checks
end
```

### 3. Test Data Setup

```ruby
# In test helper or factory
ActiveRecord::Schema.define do
  create_table :test_data, temporary: true do |t|
    # Temporary tables are safe
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shoma07/strong_schema.

## Acknowledgments

This gem stands on the shoulders of giants. Special thanks to the following project:

- [Strong Migrations](https://github.com/ankane/strong_migrations) by Andrew Kane - Safety checks for migrations

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

This gem integrates but does not modify the original libraries, which retain their respective licenses and copyrights.

