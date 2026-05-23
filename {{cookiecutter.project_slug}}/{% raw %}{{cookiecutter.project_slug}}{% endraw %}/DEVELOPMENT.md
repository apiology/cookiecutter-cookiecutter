# Development

## fix.sh

If you want to use rbenv/pyenv/etc to manage versions of tools,
there's a `fix.sh` script which may be what you'd like to install
dependencies.

## Overcommit

This project uses [overcommit](https://github.com/sds/overcommit) for
quality checks. Install hooks with `bin/overcommit --install`. The
`bin/overcommit` binstub loads Overcommit through Bundler, and
`.overcommit.yml` sets `gemfile: Gemfile` so the installed git hooks pick
up the same `overcommit` / `punchlist` gems from `Gemfile`.

If a commit is rejected because hook plugin signatures changed (typical
after editing `.git-hooks/` or bumping the gems), re-sign and retry:

```sh
bin/overcommit --sign
bin/overcommit --sign pre-commit
```

## direnv

This project uses direnv to manage environment variables used during
development.  See the `.envrc` file for detail.
