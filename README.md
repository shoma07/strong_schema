# Strong Schema

🛡️ Brings [Strong Migrations](https://github.com/ankane/strong_migrations) safety checks to schema-based database management.

## Overview

Tools using `ActiveRecord::Schema` for declarative database management lack safety checks for dangerous operations. This can lead to production issues—such as removing columns without proper safeguards or adding indexes that lock tables.

Strong Schema brings the same proven safety checks from Strong Migrations to schema-based workflows, catching unsafe operations before they reach your database.

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

### Configuration

To customize settings, create a configuration file:

```ruby
# config/strong_schema.rb
require "strong_schema"

StrongMigrations.start_after = 20260214142757
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour
StrongMigrations.auto_analyze = true
```

### Integration with Ridgepole

When using Ridgepole, load the configuration file using the `-r` option:

```bash
$ ridgepole --apply -c config/database.yml -r ./config/strong_schema.rb
```

### Ignoring Specific Operations

When you need to bypass safety checks for operations you've verified as safe, use `StrongSchema.add_ignore`:

```ruby
# config/strong_schema.rb
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

**Note:** Operations inside `change_table` blocks are detected with their original method names (`:remove_column`, `:add_column`, etc.), not as `:change_table`. The same ignore rules work for both direct operations and operations within `change_table` blocks.

## Acknowledgments

This gem stands on the shoulders of giants. Special thanks to the following project:

- [Strong Migrations](https://github.com/ankane/strong_migrations) - Safety checks for migrations

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shoma07/strong_schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
