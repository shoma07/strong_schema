# Strong Schema

🛡️ Brings [Strong Migrations](https://github.com/ankane/strong_migrations) safety checks to declarative schema definitions using `ActiveRecord::Schema`.

## Why Strong Schema?

`ActiveRecord::Schema` is commonly used for declarative schema management, but lacks the safety checks that migrations have. Strong Schema bridges this gap by integrating Strong Migrations' battle-tested checks into schema definitions.

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

To enable Strong Schema with Ridgepole, use the `-r` option:

```bash
$ ridgepole --apply -c config/database.yml -r strong_schema
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

### Ignoring Specific Operations

When you need to bypass safety checks for operations you've verified as safe, use `StrongSchema.add_ignore`:

```ruby
# config/ridgepole_setup.rb
require "strong_schema"

# Ignore a specific column removal
StrongSchema.add_ignore do |method, args|
  method == :remove_column && 
    args[0].to_s == "users" && 
    args[1].to_s == "old_email"
end

# Ignore by table name (all operations on the table)
StrongSchema.add_ignore do |method, args|
  args[0].to_s == "legacy_table"
end
```

The block receives:
- `method`: Operation symbol (`:add_column`, `:remove_column`, `:change_column`, etc.)
- `args`: Arguments array. First element is typically the table name.

**Note:** Ridgepole's `--bulk-change` flag wraps operations in `change_table` blocks, but individual operations inside are still detected with their original method names (`:remove_column`, `:add_column`, etc.). The same ignore rules work for both bulk and non-bulk modes.

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
