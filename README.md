irc-gongbot
===========

IRC bot that messages whenever gongbot is triggered.

This was extracted from an IRC bot we use internally at [Stripe](https://stripe.com).
It's far from elegant and uses a deprecated IRC library and far more EventMachine
than I ever wanted in my life. It's mostly intended as an example of building a
service on top of Gongbot.

## Dependencies

This Gem depends on the [`em-mqtt`](https://github.com/njh/ruby-em-mqtt) and [`ponder`](https://github.com/tbuehlmann/ponder) gems but recent versions
are not published on RubyGems.  You'll need to install recent versions from
the respective Github repos.

## Usage

```
require 'ponder'
require 'irc_gongbot'

irc = Ponder::Thaum.new do |thaum|
    thaum.server = '127.0.0.1'
    thaum.port = 6667
    thaum.username = 'gongbot'
    thaum.nick = 'gongbot'
    thaum.real_name = 'Gongbot'
    thaum.reconnect_interval = 10
end

gongbot = IRCGongbot::Gongbot.new(irc, 'achannel',
  'm2m.eclipse.org', 1883, '/foo/bar/test')

gongbot.run!
```
