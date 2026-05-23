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

See `.cursor/rules/overcommit-signing.mdc` for details.

## direnv

This project uses direnv to manage environment variables used during
development.  See the `.envrc` file for detail.

## Test performance

To get full realtime output from tests to debug e.g. slowness issues:

```sh
pytest tests/test_bake_project.py --capture=no -k test_bake_and_run_build
```

To also get full realtime output from the child project, you can
replace 'make test' with `time pytest tests/test_bake_project.py
--capture=no` in `test_bake_project.py`

You can debug overall test timings with:

```sh
time pytest tests/test_bake_project.py --durations=0
```

You can then wrap `time` commands around different things that shell
out, or do [this type of
technique](https://stackoverflow.com/a/1557584/2625807) for things
which aren't a simple shell-out.
