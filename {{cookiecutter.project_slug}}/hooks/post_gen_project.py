#!/usr/bin/env python

import os
import subprocess

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)


def remove_file(filepath):
    os.remove(os.path.join(PROJECT_DIRECTORY, filepath))


if __name__ == '__main__':

    if 'no' in '{% raw %}{{ cookiecutter.command_line_interface|lower }}{% endraw %}':
        cli_file = os.path.join('{% raw %}{{ cookiecutter.project_slug }}{% endraw %}', 'cli.py')
        remove_file(cli_file)

    if 'Not open source' == '{% raw %}{{ cookiecutter.open_source_license }}{% endraw %}':
        remove_file('LICENSE')

    subprocess.check_call('./fix.sh')
    subprocess.check_call(['git', 'init'])
    subprocess.check_call(['git', 'add', '-A'])
    subprocess.check_call(['git', 'commit', '-m',
                           'Initial commit from boilerplate'])
    if 'none' != '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}':
        if 'private' == '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}':
            visibility_flag = '--private'
        elif 'public' == '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}':
            visibility_flag = '--public'
        else:
            raise RuntimeError('Invalid argument to '
                               'cookiecutter.type_of_github_repo: '
                               '{% raw %}{{ cookiecutter.type_of_github_repo }}{% endraw %}')
        subprocess.check_call(['gh', 'repo', 'create',
                               visibility_flag,
                               '-y',
                               '--description',
                               '{% raw %}{{ cookiecutter.project_short_description }}{% endraw %}',
                               '{% raw %}{{ cookiecutter.github_username }}/{% endraw %}'
                               '{% raw %}{{ cookiecutter.project_slug }}{% endraw %}'])
