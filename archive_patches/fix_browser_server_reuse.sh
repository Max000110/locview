#!/usr/bin/env bash
set -e

cat > locview/utils/browser.py <<'PYEOF'
import os
import threading
import http.server
import socketserver
import subprocess
import shutil
import socket

SERVER_PORT = 8765
_server_started = False


def is_port_open(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def _serve_directory(directory):
    os.chdir(directory)

    handler = http.server.SimpleHTTPRequestHandler

    with socketserver.TCPServer(("127.0.0.1", SERVER_PORT), handler) as httpd:
        httpd.serve_forever()


def open_browser(path: str):
    global _server_started

    directory = os.path.dirname(path)
    filename = os.path.basename(path)

    if not _server_started and not is_port_open(SERVER_PORT):
        thread = threading.Thread(
            target=_serve_directory,
            args=(directory,),
            daemon=True
        )
        thread.start()
        _server_started = True

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

echo "[+] Browser Server Reuse Fix Applied"
