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
    # Add bin directory at start of PATH
    os.environ['PATH'] = os.path.join(PROJECT_DIRECTORY, 'bin') + os.pathsep + os.environ['PATH']

    if 'Not open source' == '{% raw %}{{ cookiecutter.open_source_license }}{% endraw %}':
        remove_file('LICENSE')
        remove_file('CONTRIBUTING.md')

    if os.environ.get('IN_COOKIECUTTER_PROJECT_UPGRADER', '0') == '1':
        os.environ['SKIP_GIT_CREATION'] = '1'
        os.environ['SKIP_EXTERNAL'] = '1'

    if os.environ.get('SKIP_GIT_CREATION', '0') != '1':
        # Don't run these non-idempotent things when in
        # cookiecutter_project_upgrader, which will run this hook
        # multiple times over its lifetime.
        run(['git', 'init'])
        run(['git', 'add', '-A'])
        run(['git', 'commit', '--allow-empty',
             '--no-verify',
             '-m', 'Initial commit from boilerplate'])
    #
    # (any file addition/modification from the outside world goes here)
    #
    run('./fix.sh')
    # (any lint-based auto-fixes here)
    #
    # (commit here if you brought in any files above)
    #
    run(['make', 'build-typecheck'])  # update from bundle updates
    run(['git', 'add', '-A'])
    run(['bundle', 'exec', 'git', 'commit', '--allow-empty', '-m',
         'reformat'])

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
