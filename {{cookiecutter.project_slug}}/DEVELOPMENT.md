# Development

## fix.sh

If you want to use rbenv/pyenv/etc to manage versions of tools,
there's a `fix.sh` script which may be what you'd like to install
dependencies.

## Overcommit

This project uses [overcommit](https://github.com/sds/overcommit) for
quality checks.  `bundle exec overcommit --install` will install it.

## direnv

This project uses direnv to manage environment variables used during
development.  See the `.envrc` file for detail.

## Syncing boilerplate

See [docs/SYNCING_BOILERPLATE.md](docs/SYNCING_BOILERPLATE.md). Skill: `.cursor/skills/apiology-boilerplate-sync/`. Rules: `boilerplate-sync.mdc`, `template-hierarchy.mdc`, `overcommit-signing.mdc` — interpret hierarchy at **this** tier (`{{ cookiecutter.project_slug }}`, {{ cookiecutter.language_or_tool }}).

## Conventions

* Cursor authoring policy: `~/.cursor/rules/cursor-rule-authoring.mdc` only (global).
* Repo rules: clear task `description`, `alwaysApply: false`, optional `globs` only when they cover every auto-attach case.

## Tests

To get full realtime output from tests to debug e.g. slowness issues:

```sh
pytest tests/test_bake_project.py --capture=no -k test_bake_and_run_build
```

You can debug overall test timings with:

```sh
time pytest tests/test_bake_project.py --durations=0
```

It's also useful to replace 'make test' with something that will give
you real-time stdout/stderr in `test_bake_project.py`.

You can then wrap `time` commands around different things that shell
out, or do [this type of
technique](https://stackoverflow.com/a/1557584/2625807) for things
which aren't a simple shell-out.
