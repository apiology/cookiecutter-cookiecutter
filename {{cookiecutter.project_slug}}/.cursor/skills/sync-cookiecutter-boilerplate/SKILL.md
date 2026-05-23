---
name: sync-cookiecutter-boilerplate
description: >-
  Sync boilerplate for this cookiecutter template ({{ cookiecutter.project_slug }},
  {{ cookiecutter.language_or_tool }}) from reference repos; origin/main only;
  respect ancestor/descendant hierarchy in the cookiecutter family
disable-model-invocation: false
---

# Sync cookiecutter boilerplate

**This template:** `{{ cookiecutter.project_slug }}` — {{ cookiecutter.language_or_tool }} cookiecutter.

1. Follow [apiology-boilerplate-sync](../apiology-boilerplate-sync/SKILL.md) (`git fetch` + `git show origin/main:...` only).
2. Read [docs/SYNCING_BOILERPLATE.md](../../docs/SYNCING_BOILERPLATE.md) and [template-hierarchy.mdc](../../.cursor/rules/template-hierarchy.mdc).

## Hierarchy

Templates stack general → specific (e.g. meta → `cookiecutter-ruby` → `cookiecutter-rails`). At **this** checkout:

- Port from reference repos only what fits **this** tier ({{ cookiecutter.language_or_tool }}).
- Do not push language/framework specifics to **ancestor** templates.
- Do not park **descendant-only** config here (narrower child cookiecutters own it).

## Nested template directory (if present)

Some templates include a nested `{% raw %}{{cookiecutter.project_slug}}/{% endraw %}` cookiecutter inside this repo (meta generator). When editing **this** repo’s own files, propagate shared boilerplate to that nested path only when both are still cookiecutter templates at the same family tier — otherwise treat nested paths per [template-hierarchy.mdc](../../.cursor/rules/template-hierarchy.mdc).

## Jinja / CircleCI

- Cookiecutter vars: `{{ cookiecutter.project_slug }}`, `{{ cookiecutter.language_or_tool }}`
- Circle `{{ checksum }}` in YAML: wrap in `{% raw %}...{% endraw %}` in template sources

## After edits

- Confirm changes match this template’s tier (not ancestor-only or descendant-only).
- Run this repo’s tests (`pytest`, `make`, etc. as documented in `DEVELOPMENT.md`).
