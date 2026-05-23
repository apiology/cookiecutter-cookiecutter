---
name: sync-cookiecutter-template-layers
description: >-
  Propagate boilerplate across cookiecutter-cookiecutter template layers and
  avoid breaking Circle checksum or nested bakes. Use when editing
  {{cookiecutter.project_slug}}/ or syncing this repo from reference repos.
disable-model-invocation: false
---

# Sync cookiecutter template layers

1. Follow user skill `apiology-boilerplate-sync` (`origin/main` only).
2. Read [docs/SYNCING_BOILERPLATE.md](../../docs/SYNCING_BOILERPLATE.md).

## Three layers

| Layer | Path |
|-------|------|
| Meta (pytest) | repo root |
| Generated project | `{{cookiecutter.project_slug}}/` |
| Nested cookiecutter | `{{cookiecutter.project_slug}}/{% raw %}{{cookiecutter.project_slug}}{% endraw %}/` |

## Jinja

- Cookiecutter: `{{ cookiecutter.project_slug }}`
- Circle `{{ checksum }}`: `{% raw %}{{ checksum "Gemfile" }}{% endraw %}` in template YAML

## Constraints

- Do **not** slim `{{cookiecutter.project_slug}}/requirements_dev.txt` to gem minimal deps (breaks bake).
- Root `requirements_dev.txt` keeps pytest/cookiecutter/tox.

## After edits

```bash
diff -qr '{{cookiecutter.project_slug}}' '{{cookiecutter.project_slug}}/{% raw %}{{cookiecutter.project_slug}}{% endraw %}'  # selective paths
pytest tests/test_bake_project.py
```
