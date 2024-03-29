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
