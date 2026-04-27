import logging
import os

LOG_DIR = os.path.expanduser("~/.locview/logs")
os.makedirs(LOG_DIR, exist_ok=True)

LOG_FILE = os.path.join(LOG_DIR, "locview.log")


def get_logger(name: str):
    logger = logging.getLogger(name)

    if logger.handlers:
        return logger

    logger.setLevel(logging.INFO)

    # File handler only (NO console/stdout spam)
    fh = logging.FileHandler(LOG_FILE)
    fh.setLevel(logging.INFO)

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
    )
    fh.setFormatter(formatter)

    logger.addHandler(fh)

    # Prevent bubbling to root logger / terminal
    logger.propagate = False

    return logger
