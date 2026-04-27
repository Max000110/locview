import os
import socket
import subprocess
import shutil
import time

SERVER_PORT = 8765
REPORT_DIR = "/storage/emulated/0/Documents/LocViewReports"


def is_port_open(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) == 0


def ensure_server():
    if is_port_open(SERVER_PORT):
        return True

    subprocess.Popen(
        [
            "python",
            "-m",
            "http.server",
            str(SERVER_PORT),
            "--directory",
            REPORT_DIR
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    for _ in range(30):
        if is_port_open(SERVER_PORT):
            return True
        time.sleep(0.2)

    return False


def open_browser(path: str):
    filename = os.path.basename(path)

    if not ensure_server():
        print("[ERROR] Failed to start local report server")
        return

    url = f"http://127.0.0.1:{SERVER_PORT}/{filename}"

    try:
        if shutil.which("termux-open-url"):
            subprocess.run(["termux-open-url", url], check=False)
        elif shutil.which("termux-open"):
            subprocess.run(["termux-open", url], check=False)
        else:
            print(url)

    except Exception as e:
        print("[DEBUG Browser Error]", e)
