import platform, subprocess, webbrowser, shutil

def open_url(url):
    if shutil.which("termux-open-url"):
        subprocess.run(["termux-open-url", url])
        return

    system = platform.system().lower()
    if system == "linux":
        subprocess.run(["xdg-open", url])
    elif system == "darwin":
        subprocess.run(["open", url])
    else:
        webbrowser.open(url)
