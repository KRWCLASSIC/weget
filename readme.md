# Weget `0.4`

> For now project has so much bugs i would not recommend using it for anything more than added features, replacing it with winget might be a bad idea...

Weget is winget wrapper with support with multidownload, output paths and much more!

i need to rewrite this readme btw

## Installation

To install weget (using [IronShell](https://github.com/KRWCLASSIC/IronShell) server), open PowerShell and run the following command:

```powershell
iwr utils.krwclassic.com/install/weget | iex
```

## Features

- Multi-package installation: Install multiple packages with a single command (semi-multithreaded, each in a new window)
- Custom output paths: Specify installation directories for packages

## TODO

- interactive update mode (choose on run what to update)
- find and fix all bugs (pokemon ahh)
- fix multipackage with arguments crashing

to fix (installer):

- add antivirus exception? its getting ridiculus now bro (first run of weget) ↓
- might fix via IronShell side by adding nonbinary way of installing my apps (running .py via aliases or scripts in PATH)

## Building

Required:

- Python (Preferably 3.11.x).
- Nuitka (and non-included packages used in `weget.py`).
- MSVC 2022 (Build Tools).
- Windows 10 or higher.

Make sure you exclude project folder from Microsoft Defender (Or other antiviruses)!

Run `nuitka_build.bat` and wait, if failed try again or smth, if doesn't work try chatgpt :sob:.
