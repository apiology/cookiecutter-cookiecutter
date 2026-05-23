---
name: apiology-boilerplate-sync
description: >-
  Sync boilerplate for cookiecutter-cookiecutter (meta tier) from reference repos
  using only origin/main; respect hierarchical tiers (meta, language, project).
  Use when updating this meta template, comparing reference-repo drift, or
  propagating shared boilerplate into {{cookiecutter.project_slug}}/ child templates.
disable-model-invocation: false
---

# Apiology boilerplate sync

**This repo:** `cookiecutter-cookiecutter` — meta cookiecutter that bakes language/tool templates under `{{cookiecutter.project_slug}}/`.

## Hard rule

1. `git fetch origin main` in every repo involved.
2. Read with `git show origin/main:<path>` — never treat the working tree as shipped truth.
3. Record SHAs: `git log -1 --oneline origin/main`.

Read [template-hierarchy.mdc](../../rules/template-hierarchy.mdc) at this repo root. For language-tier sync details, also read [{{cookiecutter.project_slug}}/docs/SYNCING_BOILERPLATE.md](../../../{{cookiecutter.project_slug}}/docs/SYNCING_BOILERPLATE.md) and [{{cookiecutter.project_slug}}/.cursor/skills/apiology-boilerplate-sync/SKILL.md](../../../{{cookiecutter.project_slug}}/.cursor/skills/apiology-boilerplate-sync/SKILL.md).

## Cookiecutter family (hierarchical)

Templates stack **general → specific** (meta → language/tool → project). At **this** checkout:

- Meta-wide changes belong at the repo root (this tier).
- Language/tool boilerplate belongs under `{{cookiecutter.project_slug}}/`.
- Do not push language/framework specifics to ancestor templates.
- Do not park descendant-only config at meta root.

| Tier | Path in this repo | Scope |
|------|-------------------|--------|
| Meta | Repo root | Cross-language generator; this skill |
| Language/tool | `{{cookiecutter.project_slug}}/` | Baked child cookiecutters (`cookiecutter-ruby`, etc.) |
| Project | `{{cookiecutter.project_slug}}/{{cookiecutter.project_slug}}/` | End-user project layout — no sync skill |

**Path check:** when porting `.envrc`, Makefile paths, or hook `include`s — if the referenced directory or file **does not exist** at the tier you are editing, it likely belongs in a **descendant** cookiecutter.

## Propagate to baked child templates

When syncing shared boilerplate (`.cursor/rules/`, `.cursor/skills/`, sync docs, hooks, CI), update **both** tiers when the file exists at both paths:

- Repo root (meta)
- `{{cookiecutter.project_slug}}/` (language/tool template baked from this repo)

Do not blindly duplicate meta-only config into nested project directories. See [template-hierarchy.mdc](../../rules/template-hierarchy.mdc).

## Jinja / CircleCI

- Cookiecutter vars in baked paths: `{{ cookiecutter.project_slug }}`, `{{ cookiecutter.language_or_tool }}`
- Circle `{% raw %}{{ checksum }}{% endraw %}` in YAML: wrap in `{% raw %}...{% endraw %}` in template sources

## Reference repos

Choose reference implementation(s) per task; record `origin/main` SHAs.

## Baseline paths (adjust per tier)

- `.circleci/config.yml`, `.envrc`, `.yamllint.yml`, `.gitattributes`, `.dockerignore`
- `.git-hooks/pre_commit/circle_ci.rb`, `.git-hooks/pre_commit/punchlist.rb` (maintenance)
- `.cursor/rules/`, `.cursor/skills/`, `{{cookiecutter.project_slug}}/docs/SYNCING_BOILERPLATE.md`
- `DEVELOPMENT.md` (sync / agent sections)

Before porting: `git ls-tree origin/main -- <path>`.

## Quick baseline

From the repo root:

```bash
.cursor/skills/apiology-boilerplate-sync/scripts/baseline-main.sh \
  /path/to/cookiecutter-template /path/to/reference-repo
```

After syncing boilerplate here, propagate `.cursor/skills/apiology-boilerplate-sync/` (and related rules/docs) to sibling cookiecutter repos via `make update_from_cookiecutter` or your usual template merge workflow.

## After edits

- Confirm changes match the correct tier (meta root vs `{{cookiecutter.project_slug}}/` vs nested project).
- Run this repo’s tests (`pytest`, `make`, etc. as documented in `DEVELOPMENT.md`).

## Commits in this repo

If `git commit` fails with overcommit plugin signature / security messages, run `bin/overcommit --sign`, then `bin/overcommit --sign pre-commit`, then retry. See [overcommit-signing.mdc](../../rules/overcommit-signing.mdc).
