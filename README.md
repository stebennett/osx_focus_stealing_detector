# focus-stealer

Simple macOS helper that prints the currently focused application and logs changes. Inspired by this StackExchange question: https://apple.stackexchange.com/q/123730

## Setup with uv

1) Install uv (see https://docs.astral.sh/uv/getting-started/installation/).
2) From the repo root, sync dependencies:
   - `uv sync`

## Run

- Run indefinitely: `uv run focus-stealer`
- Run for a set duration (seconds): `uv run focus-stealer --duration 300`

Press `Ctrl+C` to exit early.
