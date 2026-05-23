# Syncing boilerplate from reference repos

**This template:** `{{ cookiecutter.project_slug }}` ({{ cookiecutter.language_or_tool }} cookiecutter).

This repo is one tier in a **hierarchical** cookiecutter family (general → specific). The same workflow applies whether you are at the meta, language, or framework layer — only the **scope** changes.

## Source of truth: `origin/main` only

Do **not** use local working trees as the source of truth.

```bash
git fetch origin main
git rev-parse --short origin/main
git show origin/main:<path>
```

Record SHAs in your PR when syncing.

## Hierarchy (read at every tier)

| Direction | Rule |
|-----------|------|
| Reference → **this** template | Port only what fits **this** level ({{ cookiecutter.language_or_tool }}). |
| Reference → **descendant** templates | Do not add here; use a more specific child cookiecutter. |
| **Ancestor** → this template | Pull agnostic fixes down; never push specificity **up**. |
| **This** → **descendants** | Push tier-appropriate config down; keep narrower bits in children. |

Details: `.cursor/rules/template-hierarchy.mdc`.

## Reference repos

At sync time, choose reference implementation(s) and record their `origin/main` SHAs. Paths on disk are whatever you use locally; they are not fixed in this doc.

## Paths often in scope (language-agnostic baseline)

Adjust for **this** tier — a reference repo may include more than you should port here.

- `.circleci/config.yml`
- `.envrc`, `.yamllint.yml`, `.gitattributes`, `.dockerignore`
- `.git-hooks/pre_commit/circle_ci.rb`, `.git-hooks/pre_commit/punchlist.rb` (maintenance only)
- `.cursor/rules/`, `.cursor/skills/`, this doc
- `DEVELOPMENT.md` (agent/conventions sections)
- `CODE_OF_CONDUCT.md`, `.mdlrc`, `package.json` (usually unchanged)

Defer to **descendant** templates: app `lib/`, framework-only hooks, language stacks narrower than this repo’s scope.

### `.envrc` and `PATH_add`

- Only `PATH_add` directories that **exist in this template** (typically `bin/` when `bin/` is present).
- If a reference `.envrc` uses `PATH_add script` (or similar) and **this repo has no `script/`**, do not copy it here — add it in the descendant cookiecutter that owns `script/`.
- Missing referenced path → treat as **descendant** material (see `template-hierarchy.mdc`).

## Nested cookiecutter directory (optional)

If this template still contains a nested `{% raw %}{{cookiecutter.project_slug}}/{% endraw %}/` tree (generator meta-pattern), propagate shared boilerplate there only when that nested tree is the **same** tier. Do not blindly duplicate `.cursor/` into nested paths when the nested template is a different hierarchy level.

## Cursor rules and skills

- **Authoring policy:** `~/.cursor/rules/cursor-rule-authoring.mdc` (global only).
- **This repo:** `.cursor/rules/boilerplate-sync.mdc`, `template-hierarchy.mdc`, `overcommit-signing.mdc`.
- **Skill (in repo):** `.cursor/skills/apiology-boilerplate-sync/`.

Propagate skill and rule changes to sibling cookiecutter templates with `make update_from_cookiecutter` (or merge from the ancestor template’s `cookiecutter-template` branch).

## Checklist

1. `git fetch origin main` in every repo involved
2. List SHAs; diff only `git show origin/main:...`
3. Classify each change: this tier vs ancestor vs descendant
4. Run this repo’s tests
5. Confirm nothing came from unpushed local-only paths
