from setuptools import setup, find_packages

setup(
    name="locview",
    version="1.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "requests",
        "rich",
        "geopy",
        "timezonefinder",
        "diskcache",
        "pyyaml",
        "textual",
        "reportlab"
    ],
    entry_points={
        "console_scripts": [
            "locview=locview.main:main"
        ]
    }
)
