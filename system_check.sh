#!/bin/bash

# Exit immediately if a command exits with a non-zero status (optional for check scripts, but good practice)
# set -e

# Use echo -e for interpreting escape sequences (like colors)
# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define symbols using ASCII characters
CHECKMARK='OK'
CROSS='FAIL'

# --- Configuration ---
REQUIRED_NODE_MAJOR_VERSION="12"
NVM_DIR="$HOME/.nvm"

# --- Check Functions ---

# Function to check if a command exists
check_command() {
    local cmd_name="$1"
    local description="$2"
    echo -n "Checking $description... "
    if command -v "$cmd_name" &> /dev/null; then
        echo -e "${GREEN}${CHECKMARK}${NC}"
        return 0
    else
        echo -e "${RED}${CROSS}${NC}"
        return 1
    fi
}

# Function to check for nvm installation and sourcing
check_nvm() {
    local description="$1"
    echo -n "Checking $description... "
    if [ -d "$NVM_DIR" ]; then
        # Attempt to source nvm
        if [ -s "$NVM_DIR/nvm.sh" ]; then
             \. "$NVM_DIR/nvm.sh" &> /dev/null # Source silently
             if command -v nvm &> /dev/null; then
                 echo -e "${GREEN}${CHECKMARK}${NC}"
                 return 0
             else
                 echo -e "${RED}${CROSS}${NC} (nvm directory found, but command not available after sourcing)"
                 return 1
             fi
        else
            echo -e "${RED}${CROSS}${NC} (nvm directory found, but nvm.sh script missing)"
            return 1
        fi
    else
        echo -e "${RED}${CROSS}${NC} (nvm directory not found)"
        return 1
    fi
}

# Function to check if Node.js version 12 is currently active
check_node_version() {
    local required_version="$1"
    local description="$2"
    echo -n "Checking $description (LTS ${required_version}) is active... "

    if command -v node &> /dev/null; then
        local current_node_version=$(node -v)
        # Extract major version number for comparison
        local current_major_version=$(echo "$current_node_version" | sed 's/^v//' | cut -d. -f1)

        if [[ "$current_major_version" == "$required_version" ]]; then
             echo -e "${GREEN}${CHECKMARK}${NC} (Active: ${current_node_version})"
             return 0
        else
             echo -e "${RED}${CROSS}${NC} (Active version is ${current_node_version}, expected v${required_version}.x)"
             return 1
        fi
    else
        echo -e "${RED}${CROSS}${NC} (Node.js command not found in PATH)"
        return 1
    fi
}


# --- Script Execution ---
echo "--- System Check Results ---"

# Perform checks
check_command "git" "Git installation"
check_nvm "NVM installation"

# Check Node.js version
check_node_version "$REQUIRED_NODE_MAJOR_VERSION" "Node.js version"

check_command "yarn" "Yarn installation"
check_command "pm2" "PM2 installation"

# Perform checks for additional applications
check_command "feh" "feh installation"
check_command "vlc" "VLC installation"
check_command "mpg321" "mpg321 installation"

echo "--------------------------"
echo "Note: This check confirms the presence of executables and the active Node.js version."
echo "The PM2 startup script requires a separate manual step after initial setup."
echo "Refer to the initial setup script output for the exact command."
echo "--------------------------"

