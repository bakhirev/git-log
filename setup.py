#!/usr/bin/env python
# -*- coding: utf-8 -*-

import ast
from setuptools import find_packages, setup
from pathlib import Path
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text()

setup(
    name="assayo",
    version="0.0.21",
    author="Aleksei Bakhirev",
    author_email="alexey-bakhirev@yandex.ru",
    description="Visualization and analysis you git log. Creates HTML report about commits statistics. In addition the typical git stats, this package can show statistics by departments, tasks or determine the location of users.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/bakhirev/git-log-stat",
    packages=["bin", "assayo"],
    package_dir={
        "bin": "bin",
        "assayo": "assayo",
    },
    keywords=["git", "log", "stat", "report", "commit", "github", "audit", "statistics", "data-visualization"],
    scripts=[],
    entry_points={"console_scripts": ["assayo=bin.main:main"]},
    zip_safe=False,
    package_data = {"assayo":["assayo/**/*", "README.md"]},
    include_package_data=True,
    python_requires=">=3.6",
    license="License :: OSI Approved :: MIT License",
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Topic :: Office/Business :: Financial :: Investment",
        "Topic :: Software Development :: Version Control :: Git",
        "Intended Audience :: Developers",
        "Intended Audience :: Information Technology",
        "Intended Audience :: System Administrators",
        "Natural Language :: Chinese (Simplified)",
        "Natural Language :: English",
        "Natural Language :: German",
        "Natural Language :: Japanese",
        "Natural Language :: Korean",
        "Natural Language :: Portuguese",
        "Natural Language :: Russian",
        "Natural Language :: Spanish",
        "Operating System :: OS Independent",
        "Environment :: Web Environment",
        "Programming Language :: JavaScript",
        "Programming Language :: Python",
        # "Programming Language :: Python :: 3",
        # "Operating System :: OS Independent",
        # "Private :: Do Not Upload"
    ],
)