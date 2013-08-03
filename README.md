# Collective

It collects metrics from various services/systems and outputs them to STDOUT
using the [l2met log convetions](https://github.com/ryandotsmith/l2met/wiki/Usage#logging-convention).

```
source=erics_mac_book_pro.local measure.redis.used_memory=1.02
source=erics_mac_book_pro.local measure.redis.connected_clients=2
source=erics_mac_book_pro.local measure.sidekiq.queues.processed=1275
source=erics_mac_book_pro.local measure.sidekiq.queues.failed=128
source=erics_mac_book_pro.local measure.redis.blocked_clients=0
source=erics_mac_book_pro.local measure.redis.connected_slaves=0
source=erics_mac_book_pro.local measure.sidekiq.queues.enqueued=0
source=erics_mac_book_pro.local measure.sidekiq.workers.busy=0
```

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

```ruby
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
