# Development

## fix.sh

If you want to use rbenv/pyenv/etc to manage versions of tools,
there's a `fix.sh` script which may be what you'd like to install
dependencies.

## Worktrees

After `git worktree add`, run `./fix.sh` once in the new worktree. It
writes `.ruby-version` (gitignored) and `bundle install`s, so the
worktree's Ruby and bundler match the main checkout. Skipping this can
cause overcommit signature mismatches even after re-signing — see
[.cursor/rules/overcommit-signing.mdc](.cursor/rules/overcommit-signing.mdc).

## Overcommit

This project uses [overcommit](https://github.com/sds/overcommit) for
quality checks.  `.overcommit.yml` sets `gemfile: Gemfile` so git hooks use the
same Bundler-managed gem as `bin/overcommit`.  `bundle exec overcommit --install`
will install hooks.

If a commit fails with overcommit **plugin signature** or **security**
messages, run both sign commands before retrying (see
`.cursor/rules/overcommit-signing.mdc`):

```sh
bin/overcommit --sign
bin/overcommit --sign pre-commit
```

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
