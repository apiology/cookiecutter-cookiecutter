# Syncing boilerplate from reference repos

This cookiecutter repo is kept aligned with **language-agnostic** infrastructure from one or more **reference repos** (production projects you treat as the source of truth). Language-specific boilerplate belongs in the matching language cookiecutter (for example **cookiecutter-ruby** and its children).

## Source of truth: `origin/main` only

Do **not** use local working trees as the source of truth. Feature branches and dirty worktrees may contain files that were never pushed.

```bash
git fetch origin main
git rev-parse --short origin/main
git show origin/main:<path>
```

Record SHAs in your PR when syncing.

## Reference repos

At sync time, decide which GitHub repos are references and record their `origin/main` SHAs. Typical roles:

| Role | Example |
|------|---------|
| Template (this repo) | `apiology/cookiecutter-cookiecutter` |
| Reference implementation(s) | Whatever repos you are porting from |

Use the same clone paths you already use locally; paths are not fixed in this doc.

## Language-agnostic paths (in scope)

- `.circleci/config.yml`
- `.envrc`, `.yamllint.yml`, `.gitattributes`, `.dockerignore`
- `.git-hooks/pre_commit/circle_ci.rb`, `.git-hooks/pre_commit/punchlist.rb` (maintenance only)
- `.cursor/rules/cursor-rule-authoring.mdc`
- `DEVELOPMENT.md` (agent/conventions sections)
- `CODE_OF_CONDUCT.md`, `.mdlrc`, `package.json` (usually unchanged)

## Out of scope (language cookiecutters)

- `lib/`, `app/`, `spec/`, `test/unit/`
- `.overcommit.yml` language hooks, `Makefile`, `fix.sh` language logic
- App-specific names (`HEROKU_APP`, `bin/with-*-env`, etc.) unless templatized

Verify a path exists on main before porting:

```bash
git ls-tree origin/main -- path/to/file
```

## Template layers

Changes often belong in **three** places:

| Layer | Path |
|-------|------|
| Meta (pytest for this repo) | Repository root |
| Generated project | `{{cookiecutter.project_slug}}/` |
| Nested cookiecutter | `{{cookiecutter.project_slug}}/{% raw %}{{cookiecutter.project_slug}}{% endraw %}/` |

After edits, `diff` layer 2 vs layer 3 for parity.

## Jinja and CircleCI

- Cookiecutter variables: `{{ cookiecutter.project_slug }}`
- Circle `{{ checksum }}` in template YAML: wrap in `{% raw %}...{% endraw %}`

## Do not slim nested `requirements_dev.txt`

`{{cookiecutter.project_slug}}/requirements_dev.txt` keeps pytest/cookiecutter/tox for **bake tests**. Reference repos may use a minimal `requirements_dev.txt` on their own `main`; that is not appropriate for this meta template.

## When multiple references disagree

| Topic | Guidance |
|-------|----------|
| Hook cleanup (`@sg-ignore`, etc.) | Prefer whichever reference has the newer maintenance fix on `origin/main` |
| `.envrc`, `.yamllint` | Prefer the reference whose dev UX you want to standardize on |
| CircleCI checkout | Templatize dirname; omit debug steps (e.g. `pwd`) in timestamp jobs |

Document which reference you chose in the PR.

## Cursor skills

- User-wide: `apiology-boilerplate-sync` (`~/.cursor/skills/`)
- This repo: `sync-cookiecutter-template-layers` (`.cursor/skills/`)

## Checklist

1. `git fetch origin main` in every repo involved
2. List SHAs; diff only `git show origin/main:...`
3. Apply changes to the propagation table in the PR
4. `pytest tests/test_bake_project.py`
5. `bundle exec overcommit --run` if Ruby tooling is available
6. Confirm no ported file came from unpushed local-only paths
