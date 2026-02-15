# Strong Schema

🛡️ Brings [Strong Migrations](https://github.com/ankane/strong_migrations) safety checks to declarative schema definitions using `ActiveRecord::Schema`.

Perfect for:
- [Ridgepole](https://github.com/ridgepole/ridgepole) users
- Direct `ActiveRecord::Schema` usage
- Rails `schema.rb` files
- Any tool using `ActiveRecord::Schema`

## Why Strong Schema?

`ActiveRecord::Schema` is commonly used for declarative schema management, but lacks the safety checks that migrations have. Strong Schema bridges this gap by integrating Strong Migrations' battle-tested checks into schema definitions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'strong_schema', require: false
```

And then execute:

```bash
bundle install
```

## Usage

### With Ridgepole

To enable Strong Schema with Ridgepole, use the `-r` option:

```bash
$ ridgepole --apply -c config/database.yml -r strong_schema
```

This will automatically check your Schemafile for unsafe operations:

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

Output:

```
=== Dangerous operation detected #strong_migrations ===

Adding a column with a non-null default blocks reads and writes...

In your schema definition, you can wrap the operation with safety_assured:

safety_assured do
  add_column(:users, :settings, :json, {:default=>{}})
end
```

### Configuring Strong Migrations

To configure Strong Migrations for Ridgepole, create a setup file and require it:

```ruby
# config/ridgepole_setup.rb
require "strong_schema"

StrongMigrations.start_after = 20260214142757
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour
StrongMigrations.auto_analyze = true
```

Then run:

```bash
$ ridgepole --apply -c config/database.yml -r ./config/ridgepole_setup.rb
```

### Bypassing Safety Checks

When you're certain an operation is safe, wrap it with `safety_assured`:

```ruby
# Schemafile
safety_assured do
  remove_column :users, :old_column
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
