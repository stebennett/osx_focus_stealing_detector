#!/usr/bin/env python3
"""Prints the currently focused macOS app and logs changes."""

import argparse
import time
from typing import Optional

from AppKit import NSWorkspace


def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Log active macOS application focus changes."
    )
    parser.add_argument(
        "-d",
        "--duration",
        type=float,
        default=None,
        help="Seconds to run before exiting. Omit to run indefinitely.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> None:
    args = parse_args(argv)
    workspace = NSWorkspace.sharedWorkspace()
    active_app = workspace.activeApplication()["NSApplicationName"]
    print(f"Active focus: {active_app}")

    deadline = time.time() + args.duration if args.duration else None

    while True:
        if deadline and time.time() >= deadline:
            print("Finished: duration elapsed.")
            break

        time.sleep(1)
        new_app = workspace.activeApplication()["NSApplicationName"]
        if new_app != active_app:
            print(f"Focus changed to: {new_app}")
            active_app = new_app


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
