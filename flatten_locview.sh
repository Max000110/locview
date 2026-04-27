#!/usr/bin/env bash
set -e

mv locview/locview/* locview/ 2>/dev/null || true
rmdir locview/locview 2>/dev/null || true

cat > pyproject.toml <<'PYEOF'
[build-system]
requires = ["setuptools>=61"]
build-backend = "setuptools.build_meta"

[project]
name = "locview"
version = "1.1.0"
description = "Terminal-first geospatial intelligence toolkit"
requires-python = ">=3.9"
dependencies = [
  "requests",
  "rich",
  "geopy",
  "timezonefinder",
  "diskcache",
  "pyyaml",
  "textual"
]

[project.scripts]
locview = "locview.main:main"
PYEOF

echo "[+] Flattened package structure."
