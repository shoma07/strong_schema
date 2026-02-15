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
