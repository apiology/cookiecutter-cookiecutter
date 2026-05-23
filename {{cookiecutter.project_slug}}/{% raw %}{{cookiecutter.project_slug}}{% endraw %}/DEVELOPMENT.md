# Development

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
