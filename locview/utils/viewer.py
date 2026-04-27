import os
import subprocess
import shutil


def open_folder(path: str):
    folder = os.path.dirname(path)

    try:
        if shutil.which("termux-open"):
            subprocess.run(["termux-open", folder], check=False)
            return

        if shutil.which("termux-open-url"):
            subprocess.run(["termux-open-url", f"file://{folder}"], check=False)

    except Exception as e:
        print("[DEBUG Viewer Error]", e)
