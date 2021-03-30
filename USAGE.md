# K Log

> K Log provides console logging helpers and formatters

As a Developer, I need formatted console logs, so that information presents clearly

## Usage

### Sample Classes

#### Setup KLog

Pass a standard Logger to KLog and then setup an alias for easier access

```ruby
KLog.logger = Logger.new($stdout)
KLog.logger.level = Logger::DEBUG
KLog.logger.formatter = KLog::LogFormatter.new

L = KLog::LogUtil.new(KLog.logger)
```
