#!/usr/bin/env bash
set -e

########################################
# Browser Server Launcher
########################################
cat > locview/utils/browser.py <<'PYEOF'
import os
import threading
import http.server
import socketserver
import subprocess
import shutil

SERVER_PORT = 8765


def _serve_directory(directory):
    os.chdir(directory)

    handler = http.server.SimpleHTTPRequestHandler

    with socketserver.TCPServer(("127.0.0.1", SERVER_PORT), handler) as httpd:
        httpd.serve_forever()


def open_browser(path: str):
    directory = os.path.dirname(path)
    filename = os.path.basename(path)

    thread = threading.Thread(
        target=_serve_directory,
        args=(directory,),
        daemon=True
    )
    thread.start()

    url = f"http://127.0.0.1:{SERVER_PORT}/{filename}"

    try:
        if shutil.which("termux-open-url"):
            subprocess.run(["termux-open-url", url], check=False)
        elif shutil.which("termux-open"):
            subprocess.run(["termux-open", url], check=False)

    except Exception as e:
        print("[DEBUG Browser Error]", e)
PYEOF

pip install -e .

echo "[+] Local HTTP Report Server Enabled"
