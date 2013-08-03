# Collective

It collects metrics from various services/systems and outputs them to STDOUT
using the [l2met log convetions](https://github.com/ryandotsmith/l2met/wiki/Usage#logging-convention).

## Collectors

It includes collectors for the following:

* Sidekiq
* Redis

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'collective-metrics'
```

## Usage

Add a Collectfile:

```
use Collective::Collectors::Sidekiq
use Collective::Collectors::Redis
use Collective::Collectors::Redis, url: ENV['ROLLOUT_REDIS_URL']
```

Start the collectors.

```bash
$ collective start
```

If you're running this on heroku, just add a line to your Procfile:

```ruby
web: bundle exec rackup
collector: bundle exec collective start
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
