# focus-stealer

Simple macOS helper that prints the currently focused application and logs changes. Inspired by this StackExchange question: https://apple.stackexchange.com/q/123730

## Setup with Poetry

1) Install Poetry (recommended via `pipx install poetry`).
2) From the repo root, create/select an interpreter (Python 3.12–3.14 supported):
   - `poetry env use python3`
3) Install dependencies:
   - `poetry install`

## Run

- Run indefinitely: `poetry run focus-stealer`
- Run for a set duration (seconds): `poetry run focus-stealer --duration 300`

Press `Ctrl+C` to exit early.
