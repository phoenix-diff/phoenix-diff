# Phoenix Diff

[![Build Status](https://travis-ci.org/navinpeiris/phoenix-diff.svg?branch=master)](https://travis-ci.org/navinpeiris/phoenix-diff)

A phoenix application to show the changes between different versions of generated phoenix apps, which makes it easy to upgrade an existing app with latest changes.

Currently hosted at [http://www.phoenixdiff.org](http://www.phoenixdiff.org)

### Adding a new version of phoenix

To add a new version of phoenix, run the following mix command

```
mix phx_diff.gen.sample <phoenix_version>
```

Also, it is necessary to generate samples for other `mix phx.new` arguments,
as shown below:

```
mix phx_diff.gen.sample <phoenix_version> --binary-id
mix phx_diff.gen.sample <phoenix_version> --no-ecto
mix phx_diff.gen.sample <phoenix_version> --no-html
mix phx_diff.gen.sample <phoenix_version> --no-live
mix phx_diff.gen.sample <phoenix_version> --umbrella
```
