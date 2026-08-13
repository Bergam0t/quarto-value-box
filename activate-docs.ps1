# Dot-source this once per session before rendering/previewing example.qmd:
#   . .\activate-docs.ps1
#
# Sets QUARTO_PYTHON to this repo's .venv so Quarto's own jupyter control
# script (which needs nbclient/notebook itself, separately from whichever
# kernel it launches) resolves correctly regardless of shell activation
# state or other python/conda tooling on PATH. Path is relative to this
# script's own location, so it works no matter where the repo is cloned.
$venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Write-Error @"
No .venv found next to this script. First-time setup:
  python -m venv .venv
  .venv\Scripts\Activate.ps1
  pip install -r requirements-docs.txt
  python -m ipykernel install --user --name quarto-value-box-docs --display-name "quarto-value-box docs"
"@
    return
}

& (Join-Path $PSScriptRoot ".venv\Scripts\Activate.ps1")
$env:QUARTO_PYTHON = $venvPython
Write-Host "QUARTO_PYTHON set to $venvPython"
