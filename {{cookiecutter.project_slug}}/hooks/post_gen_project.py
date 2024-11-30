#!/usr/bin/env python

import os
import subprocess

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)


def run(*args, **kwargs):
    if len(kwargs) > 0:
        print('running with kwargs', kwargs, ':', *args, flush=True)
    else:
        print('running', *args, flush=True)
    # keep both streams in the same place so that we can weave
    # together what happened on report instead of having them
    # dumped separately
    subprocess.check_call(*args, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, **kwargs)


def remove_file(filepath):
    os.remove(os.path.join(PROJECT_DIRECTORY, filepath))


if __name__ == '__main__':
    if 'Not open source' == '{% raw %}{{ cookiecutter.open_source_license }}{% endraw %}':
        remove_file('LICENSE')
        remove_file('CONTRIBUTING.md')

    if os.environ.get('SKIP_GIT_CREATION', '0') != '1':
        # Don't run these non-idempotent things when in
        # cookiecutter_project_upgrader, which will run this hook
        # multiple times over its lifetime.
        run(['git', 'init'])
        run(['git', 'add', '-A'])
        run(['bundle', 'exec', 'git', 'commit', '--allow-empty',
             '--no-verify',
             '-m', 'Initial commit from boilerplate'])
    #
    # (any file addition/modification from the outside world goes here)
    #
    run('./fix.sh')
    run(['bundle', 'exec', 'overcommit', '--install'])
    run(['bundle', 'exec', 'overcommit', '--sign'])
    run(['bundle', 'exec', 'overcommit', '--sign', 'pre-commit'])
    run(['bundle', 'exec', 'rubocop', '-A'])
    #
    # (commit here if you brought in any files above)
    #
    # update frequently security-flagged gems
    run(['bundle', 'update', '--conservative',
         'rexml'])
    run(['git', 'add', '-A'])
    run(['make', 'build-typecheck'])  # update from bundle updates
    run(['bundle', 'exec', 'git', 'commit', '--allow-empty', '-m',
         'security updates'])

    if os.environ.get('SKIP_EXTERNAL', '0') != '1':
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
            # if repo doesn't already exist
            if subprocess.call(['gh', 'repo', 'view',
                                '{% raw %}{{ cookiecutter.github_username }}{% endraw %}/'
                                '{% raw %}{{ cookiecutter.project_slug }}{% endraw %}']) != 0:
                run(['gh', 'repo', 'create',
                     visibility_flag,
                     '--description',
                     description,
                     '--source',
                     '.',
                     '{% raw %}{{ cookiecutter.github_username }}{% endraw %}/'
                     '{% raw %}{{ cookiecutter.project_slug }}{% endraw %}'])
                run(['gh', 'repo', 'edit',
                     '--allow-update-branch',
                     '--enable-auto-merge',
                     '--delete-branch-on-merge'])
            run(['git', 'push'])
            run(['circleci', 'follow'])
            run(['git', 'branch', '--set-upstream-to=origin/main', 'main'])
