[![CircleCI](https://circleci.com/gh/navinpeiris/phoenix-diff.svg?style=svg)](https://circleci.com/gh/navinpeiris/phoenix-diff)

# Phoenix Diff

See what needs to be changed when upgrading a Phoenix framework application [http://www.phoenixdiff.org](http://www.phoenixdiff.org)

## Development

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Adding new phoenix versions to be diff'ed

The sample apps used to create the diffs are stored within the `data/sample-app` directory.

When a new version of phoenix is available, add it to the versions variable in the following script and run it to regenerate that data.

```
./bin/generate-sample-apps
```

Currently the `secret_key_base` and `signing_salt` variables must be set to the same within all the apps manually so that they don't show up in the diffs, but this should be automated pretty soon.
