# FocusStealer

A native macOS menu bar app that tracks which applications have focus. Helps identify "focus stealing" apps and understand how you spend time across applications.

Inspired by this StackExchange question: https://apple.stackexchange.com/q/123730

## Features

- Shows currently focused app in the menu bar
- **Today's Usage histogram** showing time spent per app with horizontal bars (top 5 + "Other")
- Click to see recent focus history with timestamps and durations
- Persists daily history to `~/.focus-stealer/YYYY-MM-DD.json`
- Zero CPU usage while idle (event-driven, no polling)

## Requirements

- macOS 13+ (Ventura)
- Swift 5.9+ (for building)

## Build & Run

```bash
cd FocusStealer
swift build
swift run
```

For a release build:

```bash
swift build -c release
# Binary at .build/release/FocusStealer
```

## Installation

### Download

Download `FocusStealer.app.zip` from the [Releases](https://github.com/stebennett/osx_focus_stealing_detector/releases) page and unzip it.

### Install

Move the app to your Applications folder:

```bash
mv FocusStealer.app /Applications/
```

Since the app is unsigned, you need to remove the quarantine attribute before first launch:

```bash
xattr -d com.apple.quarantine /Applications/FocusStealer.app
```

Or: Right-click the app → Open → click "Open" in the dialog.

### Start at Login

To have FocusStealer launch automatically when you log in:

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** under "Open at Login"
3. Select **FocusStealer** from Applications
4. Click **Add**

Or via Terminal:

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/FocusStealer.app", hidden:false}'
```

## Usage

1. Run the app - it appears in your menu bar showing the current app name
2. Click to see your focus history for today
3. Switch between apps - the menu bar updates and history accumulates
4. Quit via the dropdown menu or Cmd+Q

## Data Storage

History is saved to `~/.focus-stealer/` with one JSON file per day:

```
~/.focus-stealer/
├── 2026-02-04.json
├── 2026-02-05.json
└── ...
```

## Legacy Python Version

The original Python CLI tool is still available in the repository root (`focus_stealer.py`). To use it:

```bash
uv sync
uv run focus-stealer
```
