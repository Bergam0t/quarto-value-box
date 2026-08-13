# Source this once per session before rendering/previewing example.qmd:
#   source ./activate-docs.sh
#
# Sets QUARTO_PYTHON to this repo's .venv so Quarto's own jupyter control
# script (which needs nbclient/notebook itself, separately from whichever
# kernel it launches) resolves correctly regardless of shell activation
# state or other python/conda tooling on PATH. Path is relative to this
# script's own location, so it works no matter where the repo is cloned.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
venv_python="$script_dir/.venv/bin/python"

if [ ! -x "$venv_python" ]; then
    echo "No .venv found next to this script. First-time setup:" >&2
    echo "  python3 -m venv .venv" >&2
    echo "  source .venv/bin/activate" >&2
    echo "  pip install -r requirements-docs.txt" >&2
    echo '  python -m ipykernel install --user --name quarto-value-box-docs --display-name "quarto-value-box docs"' >&2
    return 1 2>/dev/null || exit 1
fi

source "$script_dir/.venv/bin/activate"
export QUARTO_PYTHON="$venv_python"
echo "QUARTO_PYTHON set to $QUARTO_PYTHON"
