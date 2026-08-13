@echo off
rem One command per session to render/preview example.qmd: sets QUARTO_PYTHON
rem to this repo's .venv so Quarto's own jupyter control script (which needs
rem nbclient/notebook itself, separately from whichever kernel it launches)
rem resolves correctly regardless of shell activation state or other
rem python/conda tooling on PATH. Path is relative to this script's own
rem location, so it works no matter where the repo is cloned.
if not exist "%~dp0.venv\Scripts\python.exe" (
    echo No .venv found next to this script. First-time setup:
    echo   python -m venv .venv
    echo   .venv\Scripts\activate.bat
    echo   pip install -r requirements-docs.txt
    echo   python -m ipykernel install --user --name quarto-value-box-docs --display-name "quarto-value-box docs"
    exit /b 1
)
call "%~dp0.venv\Scripts\activate.bat"
set "QUARTO_PYTHON=%~dp0.venv\Scripts\python.exe"
echo QUARTO_PYTHON set to %QUARTO_PYTHON%
