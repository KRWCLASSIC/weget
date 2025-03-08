@echo off
echo Building Weget with Nuitka...

:: Create build directory if it doesn't exist
if not exist "nuitka" mkdir nuitka

:: Build with Nuitka
python -m nuitka ^
    --onefile ^
    --assume-yes-for-downloads ^
    --remove-output ^
    --output-dir=nuitka ^
    --windows-company-name="KRW CLASSIC" ^
    --windows-product-name="Weget" ^
    --windows-file-description="Winget Enhancement Wrapper" ^
    --windows-file-version="0.1" ^
    weget.py

echo Build complete! Check the 'nuitka' directory for the executable.