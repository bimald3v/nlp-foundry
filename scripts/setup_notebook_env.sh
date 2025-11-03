#!/usr/bin/env bash

# shellcheck disable=SC2148
# This script must be sourced so that the virtual environment it creates
# remains active in the current shell session.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "⚠️  Please run this script with 'source scripts/setup_notebook_env.sh' so the environment"\
" stays active in your current shell."
  exit 1
fi

set -euo pipefail

ENV_NAME=".venv"
KERNEL_NAME="contrastive-learning"
PYTHON_SPEC=${PYTHON_SPEC:-}
REFRESH=false

usage() {
  echo "Usage: source scripts/setup_notebook_env.sh [--python PYTHON_SPEC] [-r|--refresh]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--refresh)
      REFRESH=true
      shift
      ;;
    --python)
      shift
      if [[ $# -eq 0 ]]; then
        echo "❌ Missing interpreter after --python"
        usage
        return 1
      fi
      PYTHON_SPEC="$1"
      shift
      ;;
    -h|--help)
      usage
      return 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      return 1
      ;;
  esac
done

if ! command -v uv >/dev/null 2>&1; then
  echo "❌ 'uv' is not installed."
  echo "Please install it using https://docs.astral.sh/uv/getting-started/installation/"
  return 1
fi

if $REFRESH && [[ -d "$ENV_NAME" ]]; then
  echo "🔄 Refreshing environment..."
  rm -rf "$ENV_NAME"
fi

if [[ -n "$PYTHON_SPEC" ]]; then
  export UV_PYTHON="$PYTHON_SPEC"
fi

if [[ ! -d "$ENV_NAME" ]]; then
  echo "📦 Creating virtual environment with uv at $ENV_NAME"
  uv venv "$ENV_NAME"
fi

if [[ -d "$ENV_NAME/bin" ]]; then
  # shellcheck disable=SC1091
  source "$ENV_NAME/bin/activate"
else
  # shellcheck disable=SC1091
  source "$ENV_NAME/Scripts/activate"
fi

echo "⬆️  Upgrading core tooling via uv"
uv pip install --upgrade pip setuptools wheel >/dev/null

echo "🔧 Installing Jupyter and kernel support"
uv pip install --upgrade jupyter ipykernel >/dev/null

echo "🧠 Registering IPython kernel: $KERNEL_NAME"
python -m ipykernel install --user --name "$KERNEL_NAME" --display-name "Contrastive Learning (local)" >/dev/null

cat <<'EOS'
✅ Notebook environment setup complete.

Next steps:
  1. Keep this shell session active (the .venv environment is enabled).
  2. Launch Jupyter (e.g., `jupyter notebook` or `jupyter lab`). Select the
     "Contrastive Learning (local)" kernel for the notebook.
  3. When you run the setup cell inside the notebook:

         try:
             import datasets
         except ModuleNotFoundError:
             !git clone https://github.com/cgpotts/cs224u/
             !pip install -r cs224u/requirements.txt
             import sys
             sys.path.append("cs224u")

     the `pip install` command will target this virtual environment.

Use `source scripts/setup_notebook_env.sh --refresh` to recreate the environment
from scratch if dependencies drift.
EOS
