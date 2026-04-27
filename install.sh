#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
pip install -r requirements.txt
pip install .
echo "Installed: use locview"
