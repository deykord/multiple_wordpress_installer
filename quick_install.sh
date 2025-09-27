#!/bin/bash
# Quick WordPress Multi-Site Installer
# One-liner deployment script

# Set TERM environment variable if not set (fixes automated deployment issues)
if [[ -z "$TERM" ]]; then
    export TERM=xterm-256color
fi

# Set non-interactive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_error "Please run: sudo $0"
    exit 1
fi

# Suppress terminal warnings and set environment for automation
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
if [[ -z "$TERM" ]]; then
    export TERM=xterm-256color
fi

# Show header
echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    WordPress Multi-Site Quick Installer${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Download and execute the installer
print_info "Downloading installer from GitHub..."

# Check if git is installed, install if needed
if ! command -v git &> /dev/null; then
    print_info "Installing git..."
    apt update -qq >/dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive apt install -y -qq git >/dev/null 2>&1
fi

# Create temporary directory
TEMP_DIR="/tmp/wp_installer_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Clone the repository
if git clone https://github.com/deykord/multiple_wordpress_installer.git . >/dev/null 2>&1; then
    print_status "Installer downloaded successfully"
else
    print_error "Failed to download installer"
    print_error "Make sure git is installed: apt update && apt install -y git"
    exit 1
fi

# Make installer executable
chmod +x multiple_wordpress_installer.sh

# Show usage if no arguments provided
if [[ $# -eq 0 ]]; then
    echo ""
    echo -e "${YELLOW}Usage Examples:${NC}"
    echo ""
    echo "# Install WordPress on multiple domains:"
    echo "bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \\"
    echo "  -u admin -p MySecurePass123 -e admin@yourdomain.com \\"
    echo "  example.com blog.example.com"
    echo ""
    echo "# Skip SSL setup:"
    echo "bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \\"
    echo "  -u admin -p MySecurePass123 -e admin@yourdomain.com --no-ssl \\"
    echo "  example.com"
    echo ""
    echo -e "${YELLOW}Required Parameters:${NC}"
    echo "  -u, --admin-user     WordPress admin username"
    echo "  -p, --admin-pass     WordPress admin password" 
    echo "  -e, --admin-email    WordPress admin email"
    echo "  [domains...]         One or more domain names"
    echo ""
    echo -e "${YELLOW}Optional Parameters:${NC}"
    echo "  -t, --title-prefix   Site title prefix (default: 'WordPress Site')"
    echo "  --no-ssl            Skip SSL certificate setup"
    echo ""
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    exit 1
fi

print_info "Starting WordPress installation..."
echo ""

# Execute the installer with provided arguments
if ./multiple_wordpress_installer.sh "$@"; then
    print_status "Installation completed successfully!"
else
    print_error "Installation failed"
    exit 1
fi

# Cleanup
print_info "Cleaning up temporary files..."
cd /
rm -rf "$TEMP_DIR"

echo ""
print_status "WordPress Multi-Site installation completed!"
print_info "Your sites should now be accessible via HTTPS"
echo ""