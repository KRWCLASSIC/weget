# Weget

Weget is winget wrapper with support with multidownload, output paths and much more!

i need to rewrite this readme btw

## TODO

- Multithreaded download mode?
- interactive update mode (choose on run what to update)
- repo-based updates (simillar to Clink)

## Building

Required:

- Python (Preferably 3.11.x).
- Nuitka (and non-included packages used in `weget.py`).
- MSVC 2022 (Build Tools).
- Windows 10 or higher.

Make sure you exclude project folder from Microsoft Defender (Or other antiviruses)!

Run `nuitka_build.bat` and wait, if failed try again or smth, if doesn't work try chatgpt :sob:.
