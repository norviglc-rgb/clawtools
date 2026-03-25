#!/bin/bash
# ClawTools Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/norviglc-rgb/clawtools/master/scripts/install.sh | bash

set -e

CLAWTOOLS_REPO="${CLAWTOOLS_REPO:-https://github.com/norviglc-rgb/clawtools.git}"
INSTALL_DIR="${HOME}/.clawtools"
BIN_DIR="${HOME}/.local/bin"

echo "╔═══════════════════════════════════════════════╗"
echo "║           ClawTools Installer v0.1.0          ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Check for Node.js
check_node() {
    if ! command -v node &> /dev/null; then
        echo "Node.js not found. Installing Node.js first..."
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
            sudo apt-get install -y nodejs
        elif command -v brew &> /dev/null; then
            brew install node@20
        else
            echo "Error: Please install Node.js 20+ manually from https://nodejs.org"
            exit 1
        fi
    fi

    NODE_VERSION=$(node --version)
    echo "Node.js: $NODE_VERSION"
}

# Create directories
create_dirs() {
    echo "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
}

# Clone or update repository
clone_repo() {
    echo "Cloning/updating ClawTools..."

    if [ -d "$INSTALL_DIR/.git" ]; then
        cd "$INSTALL_DIR"
        git pull origin master
    else
        rm -rf "$INSTALL_DIR"
        git clone --depth 1 "$CLAWTOOLS_REPO" "$INSTALL_DIR"
    fi
}

# Install dependencies and build
install_dependencies() {
    echo "Installing dependencies..."
    cd "$INSTALL_DIR"
    npm install
    npm run build
}

# Create symlinks
create_symlinks() {
    echo "Creating symlinks..."

    CLAWTOOLS_BIN="$INSTALL_DIR/bin/cli/index.js"

    if [ -d "$BIN_DIR" ]; then
        ln -sf "$CLAWTOOLS_BIN" "$BIN_DIR/clawtools"
        chmod +x "$CLAWTOOLS_BIN"
    fi

    # Try to add to PATH
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) echo "Please add $BIN_DIR to your PATH" ;;
    esac
}

# Main installation
main() {
    check_node
    create_dirs
    clone_repo
    install_dependencies
    create_symlinks

    echo ""
    echo "╔═══════════════════════════════════════════════╗"
    echo "║        Installation Complete!                ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""
    echo "Run 'clawtools' to start."
    echo "Make sure $BIN_DIR is in your PATH."
}

main "$@"
