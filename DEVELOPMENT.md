# Development

## Syncing boilerplate from reference repos

This **meta** repo (`cookiecutter-cookiecutter`) bakes tool/language cookiecutters under `{{cookiecutter.project_slug}}/`. Sync workflow, Cursor rules, and skills live **there** (not at this repo root) so each child template (`cookiecutter-ruby`, `cookiecutter-rails`, etc.) carries hierarchy-aware guidance after bake.

When editing the inner template, see `{{cookiecutter.project_slug}}/docs/SYNCING_BOILERPLATE.md`.

## fix.sh

If you want to use rbenv/pyenv/etc to manage versions of tools,
there's a `fix.sh` script which may be what you'd like to install
dependencies. It sets `git config core.hooksPath .githooks` so tracked
bootstrap hooks apply to this repo and all its worktrees.

## Git hooks and worktrees

Bootstrap hooks live in `.githooks/` (plain bash, not Overcommit) so
`post-checkout` can run `./fix.sh` on clone or `git worktree add` before
Ruby and Bundler are ready.

For a fresh clone with automatic bootstrap on checkout:

```sh
git clone -c core.hooksPath=.githooks <url>
```

Otherwise run `./fix.sh` once after clone — it sets `core.hooksPath` for
future worktrees.

After `git worktree add`, `.githooks/post-checkout` runs `./fix.sh`
automatically when the main checkout has already run `./fix.sh` at least
once. It writes `.ruby-version` (gitignored) and runs `bundle install`,
so the worktree's Ruby and bundler match the main checkout. Skipping
bootstrap can cause overcommit signature mismatches even after
re-signing — see
[.cursor/rules/overcommit-signing.mdc](.cursor/rules/overcommit-signing.mdc).

## Overcommit

This project uses [overcommit](https://github.com/sds/overcommit) for
quality checks on pre-commit, pre-push, and related hooks.
`.overcommit.yml` sets `gemfile: Gemfile` so those git hooks use the
same Bundler-managed gem as `bin/overcommit`.  `bundle exec overcommit --install`
will install hooks under `core.hooksPath`. Post-checkout bootstrap is
handled by `.githooks/post-checkout`, not Overcommit.

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
