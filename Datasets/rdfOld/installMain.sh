#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting the installation of AAS-related packages..."

VENV_NAME="aas_prod_env"
python3 -m venv $VENV_NAME
source $VENV_NAME/bin/activate
pip install --upgrade pip --quiet

# 1. Install py-aas-rdf from GitHub
echo "📦 Installing py-aas-rdf..."
pip install --upgrade --force-reinstall git+https://github.com/mhrimaz/py-aas-rdf.git@main --quiet

# 2. Install aas-core3.0
echo "📦 Installing aas-core3.0..."
pip3 install aas-core3.0

echo "✅ All packages installed successfully!"
echo "---"
echo "Environment '$VENV_NAME' is ready and active."
echo "To use this environment later, run: source $VENV_NAME/bin/activate"
