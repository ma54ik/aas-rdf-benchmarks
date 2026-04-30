#!/bin/bash

# Exit on error
set -e

echo "🛠️  Starting experimental AAS environment setup..."

VENV_NAME="aas_prod_env"
python3 -m venv $VENV_NAME
source $VENV_NAME/bin/activate
pip install --upgrade pip --quiet

# 1. Force reinstall the experimental branch of py-aas-rdf
echo "📦 Installing py-aas-rdf (Experimental branch)..."
pip install --upgrade --force-reinstall git+https://github.com/mhrimaz/py-aas-rdf.git@experimental --quiet

# 2. Install aas-core3.0
echo "📦 Installing aas-core3.0..."
pip install aas-core3.0

echo "✅✨ Installation complete! You're now on the experimental build."
echo "---"
echo "Environment '$VENV_NAME' is ready and active."
echo "To use this environment later, run: source $VENV_NAME/bin/activate"
