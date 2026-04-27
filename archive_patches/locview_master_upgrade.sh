#!/usr/bin/env bash
set -e

echo "[+] Starting LocView Master Upgrade"

########################################
# CLEANUP
########################################
rm -rf build dist .pytest_cache 2>/dev/null || true
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

mkdir -p docs tests .github/workflows
mkdir -p locview/utils

########################################
# CONFIG HARDENING
########################################
cat > locview/utils/config.py <<'EOF'
import os

DEFAULT_CONFIG = {
    "default_radius": int(os.getenv("LOCVIEW_DEFAULT_RADIUS", "500")),
    "request_timeout": int(os.getenv("LOCVIEW_TIMEOUT", "20")),
    "debug": os.getenv("LOCVIEW_DEBUG", "false").lower() == "true",
    "maptiler_key": os.getenv("LOCVIEW_MAPTILER_KEY", ""),
}

def load_config():
    return DEFAULT_CONFIG.copy()
EOF

########################################
# LOGGER
########################################
cat > locview/utils/logger.py <<'EOF'
import logging
import os

LOG_DIR = os.path.expanduser("~/.locview/logs")
os.makedirs(LOG_DIR, exist_ok=True)

LOG_PATH = os.path.join(LOG_DIR, "locview.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_PATH),
        logging.StreamHandler()
    ]
)

def get_logger(name):
    return logging.getLogger(name)
EOF

########################################
# HTTP WRAPPER W/ RETRIES
########################################
cat > locview/utils/http.py <<'EOF'
import requests
import time
from locview.utils.logger import get_logger

log = get_logger("http")

def request(method, url, retries=3, backoff=1, **kwargs):
    for attempt in range(1, retries + 1):
        try:
            r = requests.request(method, url, **kwargs)
            r.raise_for_status()
            return r
        except Exception:
            log.exception(f"HTTP failure attempt {attempt}: {url}")
            if attempt == retries:
                raise
            time.sleep(backoff * attempt)
EOF

########################################
# TEST SUITE
########################################
cat > tests/test_smoke.py <<'EOF'
def test_import_main():
    import locview.main
EOF

cat > tests/test_scoring.py <<'EOF'
from locview.intel.scoring import classify_score

def test_score_labels():
    assert classify_score(90) == "Prime"
    assert classify_score(70) == "High Potential"
EOF

cat > tests/test_risk.py <<'EOF'
from locview.intel.risk import classify_risk

def test_risk_levels():
    assert classify_risk(90) == "Low Risk"
EOF

########################################
# GITHUB ACTIONS CI
########################################
mkdir -p .github/workflows

cat > .github/workflows/ci.yml <<'EOF'
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - run: pip install -e .
      - run: pip install pytest

      - run: pytest
EOF

########################################
# TYPE CHECK CONFIG
########################################
cat > pyproject.toml <<'EOF'
[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.mypy]
python_version = "3.11"
ignore_missing_imports = true
EOF

########################################
# DOCKERFILE
########################################
cat > Dockerfile <<'EOF'
FROM python:3.11-slim

WORKDIR /app
COPY . .

RUN pip install -e .

CMD ["locview", "tui"]
EOF

########################################
# README
########################################
cat > README.md <<'EOF'
# LocView

Advanced terminal-first geospatial intelligence toolkit.

## Install
pip install -e .

## Run
locview tui

## Test
pytest
EOF

########################################
# REINSTALL
########################################
pip install -e .
pip install pytest mypy

echo "[+] Master Upgrade Complete"
