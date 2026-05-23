---
name: apiology-boilerplate-sync
description: >-
  Sync boilerplate between apiology cookiecutter templates and reference repos using
  only origin/main; respect hierarchical tiers (meta, language, framework). Use when
  updating cookiecutter templates or comparing reference-repo drift.
disable-model-invocation: false
---

# Apiology boilerplate sync

## Hard rule

1. `git fetch origin main` in every repo involved.
2. Read with `git show origin/main:<path>` — never treat the working tree as shipped truth.
3. Record SHAs: `git log -1 --oneline origin/main`.

## Cookiecutter family (hierarchical)

Templates stack **general → specific** (e.g. meta → language → framework). Each cookiecutter repo carries:

- `.cursor/rules/boilerplate-sync.mdc`, `template-hierarchy.mdc`, `overcommit-signing.mdc`
- `.cursor/skills/apiology-boilerplate-sync/`, `sync-cookiecutter-boilerplate/`
- `docs/SYNCING_BOILERPLATE.md`

**Always read the project skill and hierarchy rule in the repo you are editing** — scope differs by tier.

| Tier | Typical repo | Scope |
|------|--------------|--------|
| Meta | `cookiecutter-cookiecutter` | Bakes child templates; sync docs live under baked `{{cookiecutter.project_slug}}/` |
| Language | `cookiecutter-ruby` | {{ language_or_tool }} boilerplate |
| Framework | `cookiecutter-rails` | Narrower than language |

Do not push specificity **up** to ancestors; do not park descendant-only config at the wrong tier.

**Path check:** when porting `.envrc`, Makefile paths, or hook `include`s — if the referenced directory or file **does not exist** in the template you are editing, it likely belongs in a **descendant** cookiecutter, not the current repo.

## Reference repos

Choose reference implementation(s) per task; record `origin/main` SHAs. Examples often used: production apps/gems you treat as source of truth.

## Baseline paths (adjust per tier)

- `.circleci/config.yml`, `.envrc`, `.yamllint.yml`, `.gitattributes`, `.dockerignore`
- `.git-hooks/pre_commit/circle_ci.rb`, `.git-hooks/pre_commit/punchlist.rb` (maintenance)
- `.cursor/rules/`, `.cursor/skills/`, `docs/SYNCING_BOILERPLATE.md`
- `DEVELOPMENT.md` (sync / agent sections)

Before porting: `git ls-tree origin/main -- <path>`.

## Quick baseline

From the repo root (this cookiecutter checkout):

```bash
.cursor/skills/apiology-boilerplate-sync/scripts/baseline-main.sh \
  /path/to/cookiecutter-template /path/to/reference-repo
```

After syncing boilerplate here, propagate `.cursor/skills/apiology-boilerplate-sync/` (and related rules/docs) to sibling cookiecutter repos via `make update_from_cookiecutter` or your usual template merge workflow.

## Commits in this repo

If `git commit` fails with overcommit plugin signature / security messages, run `bin/overcommit --sign`, then `bin/overcommit --sign pre-commit`, then retry. See [overcommit-signing.mdc](../../rules/overcommit-signing.mdc).
