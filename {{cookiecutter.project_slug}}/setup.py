#!/usr/bin/env python3
"""Package metadata for the {{ cookiecutter.project_slug }} cookiecutter template."""

from distutils.core import setup

setup(
    name='{{ cookiecutter.project_slug }}',
    packages=[],
    version='0.1.0',
    description='{{ cookiecutter.project_super_short_description }}',
    author='Vince Broz',
    license='BSD',
    author_email='vince@broz.cc',
    url='https://github.com/apiology/{{ cookiecutter.project_slug }}',
    keywords=['cookiecutter', 'template', 'package', ],
    python_requires='>=3.11',
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Natural Language :: English',
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Programming Language :: Python :: 3.13',
        'Programming Language :: Python :: 3.14',
        'Programming Language :: Python :: 3.15',
        'Programming Language :: Python :: Implementation :: CPython',
        'Topic :: Software Development',
    ],
)
