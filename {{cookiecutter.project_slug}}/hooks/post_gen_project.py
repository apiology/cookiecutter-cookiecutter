#!/usr/bin/env python

import os
import subprocess

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)


def remove_file(filepath):
    os.remove(os.path.join(PROJECT_DIRECTORY, filepath))


if __name__ == '__main__':
    if 'Not open source' == '{% raw %}{{ cookiecutter.open_source_license }}{% endraw %}':
        remove_file('LICENSE')
        remove_file('CONTRIBUTING.md')

    subprocess.check_call('./fix.sh')
    if os.environ.get('IN_COOKIECUTTER_PROJECT_UPGRADER', '0') == '1':
        os.environ['SKIP_GIT_CREATION'] = '1'
        os.environ['SKIP_GITHUB_AND_CIRCLECI_CREATION'] = '1'

    if os.environ.get('SKIP_GIT_CREATION', '0') != '1':
        # Don't run these non-idempotent things when in
        # cookiecutter_project_upgrader, which will run this hook
        # multiple times over its lifetime.
        subprocess.check_call(['git', 'init'])
        subprocess.check_call(['git', 'add', '-A'])
        subprocess.check_call(['bundle', 'exec', 'overcommit', '--install'])
        subprocess.check_call(['bundle', 'exec', 'overcommit', '--sign'])
        subprocess.check_call(['bundle', 'exec', 'overcommit', '--sign', 'pre-commit'])
        subprocess.check_call(['bundle', 'exec', 'git', 'commit', '-m',
                               'Initial commit from boilerplate'])

    if os.environ.get('SKIP_GITHUB_AND_CIRCLECI_CREATION', '0') != '1':
        if 'none' != '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}':
            if 'private' == '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}':
                visibility_flag = '--private'
            elif 'public' == '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}':
                visibility_flag = '--public'
            else:
                raise RuntimeError('Invalid argument to '
                                   'cookiecutter.type_of_github_repo: '
                                   '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}')
            description = "{% raw %}{{ cookiecutter.project_short_description.replace('\"', '\\\"') }}{% endraw %}"
            subprocess.check_call(['gh', 'repo', 'create',
                                   visibility_flag,
                                   '--description',
                                   description,
                                   '--source',
                                   '.',
                                   '{% raw %}{{ cookiecutter.github_username }}/{% endraw %}'
                                   '{% raw %}{{ cookiecutter.project_slug }}{% endraw %}'])
            subprocess.check_call(['gh', 'repo', 'edit',
                                   '--allow-update-branch',
                                   '--enable-auto-merge',
                                   '--delete-branch-on-merge'])
            subprocess.check_call(['git', 'push'])
            subprocess.check_call(['circleci', 'follow'])
            subprocess.check_call(['git', 'branch', '--set-upstream-to=origin/main', 'main'])
