.PHONY: build-typecheck bundle_install cicoverage citypecheck citest citypecoverage clean clean-build clean-coverage clean-pyc clean-typecheck clean-typecoverage coverage default gem_dependencies help overcommit quality report-coverage report-coverage-to-codecov test typecheck typecoverage update_from_cookiecutter
.DEFAULT_GOAL := default

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

default: clean-typecoverage typecheck typecoverage clean-coverage test coverage quality ## run default typechecking, tests and quality

build-typecheck: types.installed  ## Fetch information that type checking depends on

clean-typecheck: ## Refresh the easily-regenerated information that type checking depends on
	@rm -fr .mypy_cache

realclean-typecheck: clean-typecheck ## Remove all type checking artifacts

realclean: clean realclean-typecheck
	rm -fr vendor .bundle
	rm .make/*
	rm *.installed

# https://app.circleci.com/pipelines/github/apiology/cookiecutter-pypackage/281/workflows/b85985a9-16d0-42c4-93d4-f965a111e090/jobs/366
typecheck: build-typecheck ## run mypy against project
	mypy --cobertura-xml-report typecover --html-report typecover hooks tests

types.installed: Gemfile.lock Gemfile.lock.installed ## Install Ruby dependencies
	touch types.installed

citypecheck: typecheck ## Run type check from CircleCI

typecoverage: typecheck ## Run type checking and then ratchet coverage in metrics/mypy_high_water_mark
	@python setup.py mypy_ratchet

clean-typecoverage: ## Clean out mypy previous results to avoid flaky results

ratchet-typecoverage: ## Run type checking, ratchet coverage, and then complain if ratchet needs to be committed
	@echo "Looking for un-checked-in type coverage metrics..."
	@git status --porcelain metrics/mypy_high_water_mark
	@test -z "$$(git status --porcelain metrics/mypy_high_water_mark)"

citypecoverage: ratchet-typecoverage ## Run type checking, ratchet coverage, and then complain if ratchet needs to be committed

clean: clean-build clean-pyc clean-test clean-mypy clean-coverage ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

requirements_dev.txt.installed: requirements_dev.txt
	pip install -q --disable-pip-version-check -r requirements_dev.txt
	touch requirements_dev.txt.installed

pip_install: requirements_dev.txt.installed ## Install Python dependencies

Gemfile.lock: Gemfile
	bundle lock

gem_dependencies:

# Ensure any Gemfile.lock changes, even pulled form git, ensure a
# bundle is installed.
Gemfile.lock.installed: Gemfile.lock Gemfile
	bundle install
	touch Gemfile.lock.installed

bundle_install: Gemfile.lock.installed ## Install Ruby dependencies

lint: ## check style with flake8
	flake8 hooks tests

test-all: ## run tests on every Python version with tox
	tox

test: ## run tests quickly
	pytest --maxfail=1 tests/test_bake_project.py --capture=no -v

citest:  ## Run unit tests from CircleCI
	pytest --maxfail=1 tests/test_bake_project.py -v

overcommit: ## run precommit quality checks
	bundle exec overcommit --run

quality: overcommit ## run precommit quality checks

bake: ## generate project using defaults
	cookiecutter $(BAKE_OPTIONS) . --overwrite-if-exists

watch: bake ## generate project using defaults and watch for changes
	watchmedo shell-command -p '*.*' -c 'make bake -e BAKE_OPTIONS=$(BAKE_OPTIONS)' -W -R -D \cookiecutter-cookiecutter/

replay: BAKE_OPTIONS=--replay ## replay last cookiecutter run and watch for changes
replay: watch
	;

clean-coverage: ## Clean out previous output of test coverage to avoid flaky results from previous runs

coverage: test report-coverage ## check code coverage

report-coverage:  ## Report summary of coverage to stdout, and generate HTML, XML coverage report

report-coverage-to-codecov: report-coverage ## use codecov.io for PR-scoped code coverage reports

update_apt: .make/apt_updated

.make/apt_updated:
	sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
	touch .make/apt_updated

cicoverage: report-coverage-to-codecov ## check code coverage, then report to codecov

update_from_cookiecutter: ## Bring in changes from template project used to create this repo
	bundle exec overcommit --uninstall
	cookiecutter_project_upgrader --help >/dev/null
	IN_COOKIECUTTER_PROJECT_UPGRADER=1 cookiecutter_project_upgrader || true
	IN_COOKIECUTTER_PROJECT_UPGRADER=1 cookiecutter_project_upgrader || true
	git checkout cookiecutter-template && git push --no-verify
	git checkout main; overcommit --sign && overcommit --sign pre-commit && git checkout main && git pull && git checkout -b update-from-cookiecutter-$$(date +%Y-%m-%d-%H%M)
	git merge cookiecutter-template || true
	git checkout --ours Gemfile.lock || true
	# update frequently security-flagged gems while we're here
	bundle update --conservative rexml || true
	make build-typecheck
	git add Gemfile.lock || true
	bundle install || true
	bundle exec overcommit --install || true
	@echo
	@echo "Please resolve any merge conflicts below and push up a PR with:"
	@echo
	@echo '   gh pr create --title "Update from cookiecutter" --body "Automated PR to update from cookiecutter boilerplate"'
	@echo
	@echo
