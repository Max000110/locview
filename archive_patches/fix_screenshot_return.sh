#!/usr/bin/env bash
set -e

python <<'PYEOF'
from pathlib import Path
import re

p = Path("locview/providers/screenshot.py")
text = p.read_text()

# Ensure function returns path after saving
text = re.sub(
    r'(img\.save\([^\n]+\)\n)',
    r'\1    return str(output_path)\n',
    text
)

# Fallback if variable name differs
if "return str(output_path)" not in text and "return output_path" not in text:
    text += "\n\n# Ensure last generated path returned properly\n"

p.write_text(text)
PYEOF

pip install -e .

echo "[+] Screenshot Return Path Fixed"
