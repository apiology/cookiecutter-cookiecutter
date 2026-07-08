#!/bin/bash
# Run cookiecutter_project_upgrader and the update_from_cookiecutter finish phase.
# Handles linked git worktrees (gitdir: .git pointer) and worktree-safe git branch ops.

set -euo pipefail

bin/overcommit --uninstall
cookiecutter_project_upgrader --help >/dev/null

MAIN_REPO_ROOT="$(dirname "$(git rev-parse --git-common-dir)")"
GIT_DIR_PATH="$(git rev-parse --git-dir)"
MAKE_DIR=".make"
TEMPLATE_BRANCH="${COOKIECUTTER_TEMPLATE_BRANCH:-cookiecutter-template}"
TEMPLATE_PARENT_SHA_FILE=".make/template-parent-sha"
TEMPLATE_UPGRADE_BRANCH="${COOKIECUTTER_TEMPLATE_UPGRADE_BRANCH:-main}"
RBS_HIDDEN=0
RUBOCOP_MAIN_HIDDEN=0
RUBOCOP_CWD_HIDDEN=0
GIT_WORKTREE_SHIM=0
REPO_CWD="$(pwd)"

cleanup_prepare() {
  if [ "${GIT_WORKTREE_SHIM}" -eq 1 ] && [ -f "${MAKE_DIR}/git-worktree-pointer" ]; then
    rm -f .git
    mv "${MAKE_DIR}/git-worktree-pointer" .git
    GIT_WORKTREE_SHIM=0
  fi
  if [ "${RBS_HIDDEN}" -eq 1 ] && [ -f "${MAKE_DIR}/rbs_collection.yaml.bak" ]; then
    mv "${MAKE_DIR}/rbs_collection.yaml.bak" "${MAIN_REPO_ROOT}/rbs_collection.yaml"
    rm -f "${MAKE_DIR}/rbs_collection_yaml_hidden"
    RBS_HIDDEN=0
  fi
  if [ "${RUBOCOP_MAIN_HIDDEN}" -eq 1 ] && [ -f "${MAKE_DIR}/rubocop-main.yml.bak" ]; then
    mv "${MAKE_DIR}/rubocop-main.yml.bak" "${MAIN_REPO_ROOT}/.rubocop.yml"
    rm -f "${MAKE_DIR}/rubocop_main_hidden"
    RUBOCOP_MAIN_HIDDEN=0
  fi
  if [ "${RUBOCOP_CWD_HIDDEN}" -eq 1 ] && [ -f "${MAKE_DIR}/rubocop-cwd.yml.bak" ]; then
    mv "${MAKE_DIR}/rubocop-cwd.yml.bak" "${REPO_CWD}/.rubocop.yml"
    rm -f "${MAKE_DIR}/rubocop_cwd_hidden"
    RUBOCOP_CWD_HIDDEN=0
  fi
  if [ -d "${GIT_DIR_PATH}/cookiecutter" ]; then
    rm -rf "${GIT_DIR_PATH}/cookiecutter"
  fi
}

trap cleanup_prepare EXIT

mkdir -p "${MAKE_DIR}"

CONTEXT_FILE="${MAKE_DIR}/cookiecutter_context.json"
if [ -f docs/cookiecutter_input.json ]; then
  jq 'del(._output_dir, ._repo_dir, ._checkout)' docs/cookiecutter_input.json \
    > "${CONTEXT_FILE}"
fi

template_url_from_context() {
  jq -r '._template // empty' "${CONTEXT_FILE}"
}

cookiecutter_cache_dir() {
  local template_url=$1
  local repo_name=""

  if [[ "${template_url}" =~ github\.com[:/][^/]+/([^/.]+)(\.git)?/?$ ]]; then
    repo_name="${BASH_REMATCH[1]}"
  elif [[ "${template_url}" =~ ^git@github\.com:[^/]+/([^/.]+)(\.git)?$ ]]; then
    repo_name="${BASH_REMATCH[1]}"
  else
    return 1
  fi

  echo "${HOME}/.cookiecutters/${repo_name}"
}

refresh_template_cache() {
  local template_url=$1
  local upgrade_branch=$2
  local cache_dir=""

  if ! cache_dir="$(cookiecutter_cache_dir "${template_url}")"; then
    echo "warning: could not derive cookiecutter cache dir from template URL: ${template_url}" >&2
    return 0
  fi

  if [ ! -d "${cache_dir}/.git" ]; then
    echo "cookiecutter cache not present yet at ${cache_dir}; cookiecutter will clone on bake" >&2
    return 0
  fi

  echo "Refreshing cookiecutter template cache ${cache_dir} @ ${upgrade_branch}"
  git -C "${cache_dir}" fetch origin "${upgrade_branch}"
  git -C "${cache_dir}" checkout "${upgrade_branch}"
  git -C "${cache_dir}" merge --ff-only "origin/${upgrade_branch}"
}

resolve_template_parent_sha() {
  local template_url=$1
  local upgrade_branch=$2

  if git remote get-url cookiecutter-upstream >/dev/null 2>&1; then
    git fetch cookiecutter-upstream "${upgrade_branch}"
    git rev-parse "cookiecutter-upstream/${upgrade_branch}"
    return 0
  fi

  local cache_dir=""
  if cache_dir="$(cookiecutter_cache_dir "${template_url}")" && [ -d "${cache_dir}/.git" ]; then
    git -C "${cache_dir}" rev-parse "origin/${upgrade_branch}"
    return 0
  fi

  git fetch origin "${upgrade_branch}"
  git rev-parse "origin/${upgrade_branch}"
}

read_template_parent_stamp() {
  if git rev-parse --verify "${TEMPLATE_BRANCH}" >/dev/null 2>&1; then
    git show "${TEMPLATE_BRANCH}:${TEMPLATE_PARENT_SHA_FILE}" 2>/dev/null | tr -d '[:space:]' || true
  fi
}

stamp_template_parent_sha() {
  local parent_sha=$1
  local stamp_worktree=""

  stamp_worktree="$(mktemp -d "${TMPDIR:-/tmp}/cookiecutter-template-stamp.XXXXXX")"
  cleanup_stamp_worktree() {
    git worktree remove --force "${stamp_worktree}" >/dev/null 2>&1 || true
    rm -rf "${stamp_worktree}"
  }
  trap cleanup_stamp_worktree RETURN

  git worktree add --detach "${stamp_worktree}" "${TEMPLATE_BRANCH}"
  mkdir -p "${stamp_worktree}/.make"
  printf '%s\n' "${parent_sha}" > "${stamp_worktree}/${TEMPLATE_PARENT_SHA_FILE}"
  if git -C "${stamp_worktree}" diff --quiet -- "${TEMPLATE_PARENT_SHA_FILE}"; then
    echo "template-parent-sha already recorded on ${TEMPLATE_BRANCH}"
    return 0
  fi
  git -C "${stamp_worktree}" add "${TEMPLATE_PARENT_SHA_FILE}"
  git -C "${stamp_worktree}" commit -m "Record template parent SHA ${parent_sha:0:12}"
  git push origin "HEAD:${TEMPLATE_BRANCH}"
}

verify_template_branch_freshness() {
  local parent_sha=$1
  local tip_before=$2
  local tip_after=$3
  local stamp=""

  stamp="$(read_template_parent_stamp)"
  if [ "${tip_before}" != "${tip_after}" ]; then
    if [ "${stamp}" != "${parent_sha}" ]; then
      stamp_template_parent_sha "${parent_sha}"
    fi
    echo "Re-baked ${TEMPLATE_BRANCH}: ${tip_before:0:12} -> ${tip_after:0:12} @ parent ${parent_sha:0:12}"
    return 0
  fi

  if [ "${stamp}" = "${parent_sha}" ]; then
    echo "Template branch already matches parent ${parent_sha:0:12}; continuing idempotently"
    return 0
  fi

  >&2 echo "error: ${TEMPLATE_BRANCH} tip unchanged (${tip_after:0:12}) but parent is ${parent_sha:0:12}"
  >&2 echo "       recorded stamp: ${stamp:-<missing>}"
  >&2 echo "       Refresh failed or bake used stale template cache; fix cache/upstream and retry."
  exit 1
}

if [ -f "${MAIN_REPO_ROOT}/rbs_collection.yaml" ]; then
  mv "${MAIN_REPO_ROOT}/rbs_collection.yaml" "${MAKE_DIR}/rbs_collection.yaml.bak"
  touch "${MAKE_DIR}/rbs_collection_yaml_hidden"
  RBS_HIDDEN=1
fi
if [ -f "${MAIN_REPO_ROOT}/.rubocop.yml" ]; then
  mv "${MAIN_REPO_ROOT}/.rubocop.yml" "${MAKE_DIR}/rubocop-main.yml.bak"
  touch "${MAKE_DIR}/rubocop_main_hidden"
  RUBOCOP_MAIN_HIDDEN=1
fi
# Nested tiers may have their own .rubocop.yml; hide it so RuboCop does not inherit
# mismatched config while cookiecutter_project_upgrader runs under .git/cookiecutter/
if [ -f "${REPO_CWD}/.rubocop.yml" ]; then
  mv "${REPO_CWD}/.rubocop.yml" "${MAKE_DIR}/rubocop-cwd.yml.bak"
  touch "${MAKE_DIR}/rubocop_cwd_hidden"
  RUBOCOP_CWD_HIDDEN=1
fi

if [ -f .make/git-worktree-pointer ] && [ ! -f .git ] && [ ! -L .git ]; then
  echo "error: stale ${MAKE_DIR}/git-worktree-pointer but .git is missing; restore manually" >&2
  exit 1
fi

if [ -f .git ] && [ ! -L .git ] && grep -q '^gitdir: ' .git; then
  cp .git "${MAKE_DIR}/git-worktree-pointer"
  rm -f .git
  ln -s "${GIT_DIR_PATH}" .git
  GIT_WORKTREE_SHIM=1
elif [ -f .git ] && [ ! -L .git ]; then
  echo "error: .git is a regular file but not a linked-worktree gitdir pointer" >&2
  exit 1
fi

TEMPLATE_URL=""
if [ -f "${CONTEXT_FILE}" ]; then
  TEMPLATE_URL="$(template_url_from_context)"
fi
if [ -n "${TEMPLATE_URL}" ]; then
  refresh_template_cache "${TEMPLATE_URL}" "${TEMPLATE_UPGRADE_BRANCH}"
fi
PARENT_SHA="$(resolve_template_parent_sha "${TEMPLATE_URL}" "${TEMPLATE_UPGRADE_BRANCH}")"
echo "Template parent SHA (${TEMPLATE_UPGRADE_BRANCH}): ${PARENT_SHA}"

if git rev-parse --verify "${TEMPLATE_BRANCH}" >/dev/null 2>&1; then
  TEMPLATE_TIP_BEFORE="$(git rev-parse "${TEMPLATE_BRANCH}")"
else
  TEMPLATE_TIP_BEFORE=""
fi

export IN_COOKIECUTTER_PROJECT_UPGRADER=1
UPGRADER_ARGS=(-p true -u "${TEMPLATE_UPGRADE_BRANCH}")
if [ -f "${CONTEXT_FILE}" ]; then
  UPGRADER_ARGS=(-c "${CONTEXT_FILE}" "${UPGRADER_ARGS[@]}")
fi
if ! cookiecutter_project_upgrader "${UPGRADER_ARGS[@]}"; then
  if [ -z "${TEMPLATE_TIP_BEFORE}" ] || ! git rev-parse --verify "${TEMPLATE_BRANCH}" >/dev/null 2>&1; then
    >&2 echo "error: cookiecutter_project_upgrader failed and ${TEMPLATE_BRANCH} is missing"
    exit 1
  fi
  echo "cookiecutter_project_upgrader reported no template diff; checking parent SHA stamp"
fi

TEMPLATE_TIP_AFTER="$(git rev-parse "${TEMPLATE_BRANCH}")"
verify_template_branch_freshness "${PARENT_SHA}" "${TEMPLATE_TIP_BEFORE}" "${TEMPLATE_TIP_AFTER}"

trap - EXIT
cleanup_prepare

# Finish phase (worktree-safe: no checkout of branches locked in other worktrees)
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
if git symbolic-ref -q "refs/remotes/origin/HEAD" >/dev/null 2>&1; then
  DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
fi

if ! git diff --quiet -- Makefile 2>/dev/null || ! git diff --cached --quiet -- Makefile 2>/dev/null; then
  git stash push -m 'update_from_cookiecutter Makefile' -- Makefile
  touch "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

git push --no-verify origin "${TEMPLATE_BRANCH}"

git fetch "origin" "${DEFAULT_BRANCH}"
UPDATE_BRANCH="update-from-cookiecutter-$(date +%Y-%m-%d-%H%M)"
git switch -c "${UPDATE_BRANCH}" "origin/${DEFAULT_BRANCH}"
echo "Created branch ${UPDATE_BRANCH} from origin/${DEFAULT_BRANCH}"

bin/overcommit --sign
bin/overcommit --sign pre-commit
bin/overcommit --sign pre-push

git merge "${TEMPLATE_BRANCH}"
git checkout --ours Gemfile.lock || true

if [ -f "${MAKE_DIR}/cookiecutter_makefile_stashed" ]; then
  git stash pop || true
  rm -f "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

bundle update --conservative json rexml || true
( make build && git add Gemfile.lock ) || true
bin/overcommit --install || true

echo
echo "Please resolve any merge conflicts below and push up a PR with:"
echo
echo '   gh pr create --title "Update from upstream" --body "Automated PR to update from upstream boilerplate"'
echo
