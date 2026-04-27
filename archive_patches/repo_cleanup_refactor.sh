#!/usr/bin/env bash
set -e

########################################
# Create Clean Canonical Structure
########################################
mkdir -p locview/{core,intel,export,providers,alerts,live,tui,utils,db}
mkdir -p tests docs

########################################
# Remove Build/Cache Artifacts
########################################
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true

########################################
# Ensure Package Init Files
########################################
for dir in \
    locview \
    locview/core \
    locview/intel \
    locview/export \
    locview/providers \
    locview/alerts \
    locview/live \
    locview/tui \
    locview/utils \
    locview/db
do
    touch "$dir/__init__.py"
done

########################################
# .gitignore
########################################
cat > .gitignore <<'GITEOF'
__pycache__/
*.pyc
*.pyo
*.egg-info/
build/
dist/
.env
.locview/
*.db
GITEOF

########################################
# README
########################################
cat > README.md <<'MDEOF'
# LocView

Advanced terminal-first geospatial intelligence and reconnaissance toolkit.

## Features
- Reverse geocoding
- Weather / POI intelligence
- Satellite previews
- HTML / PDF reports
- Polygon scanning + heatmaps
- AI hotspot scoring
- Trend analysis
- Geofence alerts
- Live tracking
- Plugin provider architecture

## Install

pip install -e .

## Run

locview tui
MDEOF

########################################
# Architecture Docs
########################################
cat > docs/ARCHITECTURE.md <<'DOCEOF'
# LocView Architecture

core/       -> Scan / compare / polygon engines
intel/      -> Scoring / trends / risk analysis
providers/  -> External provider integrations
export/     -> HTML / PDF / heatmap rendering
alerts/     -> Geofencing / alert systems
live/       -> Live tracking systems
tui/        -> Terminal dashboard
utils/      -> Shared utilities
db/         -> Persistence layer
DOCEOF

########################################
# Smoke Test
########################################
cat > tests/test_smoke.py <<'PYEOF'
def test_import_main():
    import locview.main
PYEOF

pip install -e .

echo "[+] Repository Cleanup Complete"
