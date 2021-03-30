# K Log

> K Log provides console logging helpers and formatters

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'k_log'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install k_log
```

## Stories

### Main Story

As a Developer, I need formatted console logs, so that information presents clearly

See all [stories](./STORIES.md)

## Usage

See all [usage examples](./USAGE.md)

### Basic Example

#### Setup KLog

Pass a standard Logger to KLog and then setup an alias for easier access

```ruby
KLog.logger = Logger.new($stdout)
KLog.logger.level = Logger::DEBUG
KLog.logger.formatter = KLog::LogFormatter.new

L = KLog::LogUtil.new(KLog.logger)
```

#### Sample Usage

```ruby
L.debug 'some debug message'
L.info 'some info message'
L.warn 'some warning message'
L.error 'some error message'
L.fatal 'some fatal message'

L.kv('First Name', 'David')
L.kv('Last Name', 'Cruwys')
L.kv('Age', 45)
L.kv('Sex', 'male')

L.line
L.line(20)
L.line(20, character: '-')

L.heading('Heading')
L.subheading('Sub Heading')
```

## Development

Checkout the repo

```bash
git clone klueless-io/k_log
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

```bash
bin/console

Aaa::Bbb::Program.execute()
# => ""
```

`k_log` is setup with Guard, run `guard`, this will watch development file changes and run tests automatically, if successful, it will then run rubocop for style quality.

To release a new version, update the version number in `version.rb`, build the gem and push the `.gem` file to [rubygems.org](https://rubygems.org).

```bash
rake publish
rake clean
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klueless-io/k_log. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the K Log project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/klueless-io/k_log/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) David Cruwys. See [MIT License](LICENSE.txt) for further details.
