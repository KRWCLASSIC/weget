# Weget `0.3`

Weget is winget wrapper with support with multidownload, output paths and much more!

i need to rewrite this readme btw

## Instalation

To install weget, open PowerShell and run the following command:

```powershell
iwr weget.krwclassic.com | iex
```

## Features

- fill later lol, and make this img smaller fr \/

![weget help preview](https://github.com/user-attachments/assets/e48391c8-1a53-4df1-911c-c56102e39d3a)

## TODO

- Multithreaded download/install/upgrade?
- interactive update mode (choose on run what to update)
- repo-based updates (simillar to Clink)

to fix (installer):

- THE "C"
- add antivirus exception? its getting ridiculus now bro

## Building

Required:

- Python (Preferably 3.11.x).
- Nuitka (and non-included packages used in `weget.py`).
- MSVC 2022 (Build Tools).
- Windows 10 or higher.

Make sure you exclude project folder from Microsoft Defender (Or other antiviruses)!

Run `nuitka_build.bat` and wait, if failed try again or smth, if doesn't work try chatgpt :sob:.
