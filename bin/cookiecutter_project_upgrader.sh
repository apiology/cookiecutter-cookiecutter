#!/bin/bash
# Run cookiecutter_project_upgrader and the update_from_cookiecutter finish phase.
# Handles linked git worktrees (gitdir: .git pointer) and worktree-safe git branch ops.

set -euo pipefail

bin/overcommit --uninstall
cookiecutter_project_upgrader --help >/dev/null

MAIN_REPO_ROOT="$(dirname "$(git rev-parse --git-common-dir)")"
GIT_DIR_PATH="$(git rev-parse --git-dir)"
MAKE_DIR=".make"
STAMP_FILE="${MAKE_DIR}/template-parent-sha"
TEMPLATE_BRANCH="${COOKIECUTTER_TEMPLATE_BRANCH:-cookiecutter-template}"
TEMPLATE_UPGRADE_BRANCH="${COOKIECUTTER_TEMPLATE_UPGRADE_BRANCH:-main}"
GIT_WORKTREE_SHIM=0
REPO_CWD="$(pwd)"
HIDDEN_BACKUPS=()

hide_for_bake() {
  local src=$1 bak=$2
  if [ -f "${src}" ]; then
    mv "${src}" "${bak}"
    HIDDEN_BACKUPS+=("${bak}|${src}")
  fi
}

restore_hidden() {
  local entry bak dest
  for entry in "${HIDDEN_BACKUPS[@]}"; do
    bak="${entry%%|*}"
    dest="${entry#*|}"
    [ -f "${bak}" ] && mv "${bak}" "${dest}"
  done
  HIDDEN_BACKUPS=()
}

cleanup_prepare() {
  if [ "${GIT_WORKTREE_SHIM}" -eq 1 ] && [ -f "${MAKE_DIR}/git-worktree-pointer" ]; then
    rm -f .git
    mv "${MAKE_DIR}/git-worktree-pointer" .git
    GIT_WORKTREE_SHIM=0
  fi
  restore_hidden
  [ -d "${GIT_DIR_PATH}/cookiecutter" ] && rm -rf "${GIT_DIR_PATH}/cookiecutter"
}

trap cleanup_prepare EXIT

mkdir -p "${MAKE_DIR}"

CONTEXT_FILE="${MAKE_DIR}/cookiecutter_context.json"
TEMPLATE_URL=""
if [ -f docs/cookiecutter_input.json ]; then
  jq 'del(._output_dir, ._repo_dir, ._checkout)' docs/cookiecutter_input.json \
    > "${CONTEXT_FILE}"
  TEMPLATE_URL="$(jq -r '._template // empty' "${CONTEXT_FILE}")"
fi

cookiecutter_cache_dir() {
  local url=$1 name=""
  if [[ "${url}" =~ github\.com[:/][^/]+/([^/.]+) ]]; then
    name="${BASH_REMATCH[1]}"
  elif [[ "${url}" =~ ^git@github\.com:[^/]+/([^/.]+) ]]; then
    name="${BASH_REMATCH[1]}"
  else
    return 1
  fi
  printf '%s\n' "${HOME}/.cookiecutters/${name}"
}

refresh_template_cache() {
  local url=$1 branch=$2 cache=""
  cache="$(cookiecutter_cache_dir "${url}")" || {
    echo "warning: could not derive cookiecutter cache dir from: ${url}" >&2
    return 0
  }
  if [ ! -d "${cache}/.git" ]; then
    echo "cookiecutter cache not present at ${cache}; clone on bake" >&2
    return 0
  fi
  echo "Refreshing cookiecutter cache ${cache} @ ${branch}"
  git -C "${cache}" fetch origin "${branch}"
  git -C "${cache}" checkout "${branch}"
  git -C "${cache}" merge --ff-only "origin/${branch}"
}

resolve_template_parent_sha() {
  local url=$1 branch=$2 cache=""
  if git remote get-url cookiecutter-upstream &>/dev/null; then
    git fetch cookiecutter-upstream "${branch}"
    git rev-parse "cookiecutter-upstream/${branch}"
    return 0
  fi
  if cache="$(cookiecutter_cache_dir "${url}")" && [ -d "${cache}/.git" ]; then
    git -C "${cache}" rev-parse "origin/${branch}"
    return 0
  fi
  git fetch origin "${branch}"
  git rev-parse "origin/${branch}"
}

read_template_parent_stamp() {
  git rev-parse --verify "${TEMPLATE_BRANCH}" &>/dev/null \
    || return 0
  git show "${TEMPLATE_BRANCH}:${STAMP_FILE}" 2>/dev/null | tr -d '[:space:]' || true
}

stamp_template_parent_sha() {
  local parent_sha=$1 wt=""
  wt="$(mktemp -d)"
  trap 'git worktree remove --force "${wt}" &>/dev/null; rm -rf "${wt}"' RETURN

  git worktree add --detach "${wt}" "${TEMPLATE_BRANCH}"
  mkdir -p "${wt}/${MAKE_DIR}"
  printf '%s\n' "${parent_sha}" > "${wt}/${STAMP_FILE}"
  if git -C "${wt}" diff --quiet -- "${STAMP_FILE}"; then
    echo "template-parent-sha already on ${TEMPLATE_BRANCH}"
    return 0
  fi
  git -C "${wt}" add "${STAMP_FILE}"
  git -C "${wt}" commit -m "Record template parent SHA ${parent_sha:0:12}"
  git push origin "HEAD:${TEMPLATE_BRANCH}"
}

verify_template_branch_freshness() {
  local parent_sha=$1 tip_before=$2 tip_after=$3 stamp=""
  stamp="$(read_template_parent_stamp)"

  if [ "${tip_before}" != "${tip_after}" ]; then
    [ "${stamp}" != "${parent_sha}" ] && stamp_template_parent_sha "${parent_sha}"
    echo "Re-baked ${TEMPLATE_BRANCH}: ${tip_before:0:12} -> ${tip_after:0:12} @ ${parent_sha:0:12}"
    return 0
  fi
  if [ "${stamp}" = "${parent_sha}" ]; then
    echo "Template branch matches parent ${parent_sha:0:12}; idempotent"
    return 0
  fi

  >&2 cat <<EOF
error: ${TEMPLATE_BRANCH} tip unchanged (${tip_after:0:12}) but parent is ${parent_sha:0:12}
       recorded stamp: ${stamp:-<missing>}
       Refresh failed or bake used stale cache; fix upstream/cache and retry.
EOF
  exit 1
}

hide_for_bake "${MAIN_REPO_ROOT}/rbs_collection.yaml" "${MAKE_DIR}/rbs_collection.yaml.bak"
hide_for_bake "${MAIN_REPO_ROOT}/.rubocop.yml" "${MAKE_DIR}/rubocop-main.yml.bak"
hide_for_bake "${REPO_CWD}/.rubocop.yml" "${MAKE_DIR}/rubocop-cwd.yml.bak"

if [ -f .make/git-worktree-pointer ] && [ ! -e .git ]; then
  echo "error: stale ${MAKE_DIR}/git-worktree-pointer but .git missing" >&2
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

[ -n "${TEMPLATE_URL}" ] && refresh_template_cache "${TEMPLATE_URL}" "${TEMPLATE_UPGRADE_BRANCH}"
PARENT_SHA="$(resolve_template_parent_sha "${TEMPLATE_URL}" "${TEMPLATE_UPGRADE_BRANCH}")"
echo "Template parent SHA (${TEMPLATE_UPGRADE_BRANCH}): ${PARENT_SHA}"

TEMPLATE_TIP_BEFORE=""
if git rev-parse --verify "${TEMPLATE_BRANCH}" &>/dev/null; then
  TEMPLATE_TIP_BEFORE="$(git rev-parse "${TEMPLATE_BRANCH}")"
fi

export IN_COOKIECUTTER_PROJECT_UPGRADER=1
UPGRADER_ARGS=(-p true -u "${TEMPLATE_UPGRADE_BRANCH}")
[ -f "${CONTEXT_FILE}" ] && UPGRADER_ARGS=(-c "${CONTEXT_FILE}" "${UPGRADER_ARGS[@]}")
if ! cookiecutter_project_upgrader "${UPGRADER_ARGS[@]}"; then
  if [ -z "${TEMPLATE_TIP_BEFORE}" ] \
    || ! git rev-parse --verify "${TEMPLATE_BRANCH}" &>/dev/null; then
    >&2 echo "error: upgrader failed and ${TEMPLATE_BRANCH} is missing"
    exit 1
  fi
  echo "cookiecutter_project_upgrader reported no template diff; checking parent SHA stamp"
fi

verify_template_branch_freshness "${PARENT_SHA}" "${TEMPLATE_TIP_BEFORE}" \
  "$(git rev-parse "${TEMPLATE_BRANCH}")"

trap - EXIT
cleanup_prepare

DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
if git symbolic-ref -q refs/remotes/origin/HEAD &>/dev/null; then
  DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
fi

if ! git diff --quiet -- Makefile 2>/dev/null \
  || ! git diff --cached --quiet -- Makefile 2>/dev/null; then
  git stash push -m 'update_from_cookiecutter Makefile' -- Makefile
  touch "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

git push --no-verify origin "${TEMPLATE_BRANCH}"
git fetch origin "${DEFAULT_BRANCH}"

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

cat <<'EOF'

Please resolve any merge conflicts below and push up a PR with:

   gh pr create --title "Update from upstream" --body "Automated PR to update from upstream boilerplate"

EOF
