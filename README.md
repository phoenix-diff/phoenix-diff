# Phoenix Diff

[![Build Status](https://travis-ci.org/navinpeiris/phoenix-diff.svg?branch=master)](https://travis-ci.org/navinpeiris/phoenix-diff)

A phoenix application to show the changes between different versions of generated phoenix apps, which makes it easy to upgrade an existing app with latest changes.

Currently hosted at [http://www.phoenixdiff.org](http://www.phoenixdiff.org)

### Adding a new version of phoenix

To add a new version of phoenix, run the following mix command

```
mix phx_diff.add <phoenix-version>
```

The above mix task uses the following two tasks behind the hood:

- `mix phx_diff.gen.sample` - Generates a sample app for the given version
- `mix phx_diff.gen.diffs` - Generates the diff files between all the different versions
