#!/bin/bash
# Node.js installation script for Linux/macOS/WSL

set -e

echo "Checking for Node.js..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "Node.js $NODE_VERSION is already installed"

    # Check if version meets requirement
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | tr -d 'v')
    if [ "$NODE_MAJOR" -lt 20 ]; then
        echo "Node.js version 20+ is required. Upgrading..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
        sudo apt-get install -y nodejs
    fi
else
    echo "Node.js not found. Installing..."

    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
        sudo apt-get install -y nodejs
    elif command -v brew &> /dev/null; then
        # macOS
        brew install node@20
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
        sudo yum install -y nodejs
    else
        echo "No supported package manager found. Please install Node.js manually."
        echo "Visit: https://nodejs.org/"
        exit 1
    fi
fi

echo "Verifying installation..."
node --version
npm --version

echo ""
echo "Node.js installation complete!"
