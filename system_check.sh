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
REQUIRED_PYTHON_MAJOR_VERSION="3"
REQUIRED_PYTHON_MINOR_VERSION="9"
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

# Function to check if PM2 startup service is active and enabled (primarily for systemd)
check_pm2_startup() {
    local description="$1"
    local service_name="pm2-$(whoami)" # PM2 service name typically includes the username

    echo -n "Checking $description ('$service_name')... "

    # Check if systemctl command exists (indicates systemd)
    if command -v systemctl &> /dev/null; then
        # Check if the service is active
        if systemctl is-active --quiet "$service_name"; then
            # Check if the service is enabled
            if systemctl is-enabled --quiet "$service_name"; then
                echo -e "${GREEN}${CHECKMARK}${NC} (Active and Enabled)"
                return 0
            else
                echo -e "${RED}${CROSS}${NC} (Active but Disabled - will not start on boot)"
                return 1
            fi
        else
            # Service is not active, check if it's enabled anyway
            if systemctl is-enabled --quiet "$service_name"; then
                 echo -e "${RED}${CROSS}${NC} (Inactive but Enabled - might start on boot but not currently running)"
                 return 1
            else
                 echo -e "${RED}${CROSS}${NC} (Inactive and Disabled - not running and will not start on boot)"
                 return 1
            fi
        fi
    else
        # systemctl not found - cannot check systemd service status
        echo -e "${RED}${CROSS}${NC} (Cannot check - systemctl command not found. Not a systemd system?)"
        return 1
    fi
}

# Function to check Python version (must be 3.9.x)
check_python_version() {
    REQUIRED_MAJOR=$1
    REQUIRED_MINOR=$2
    printf "Checking Python version (%s.%s.x)... " "$REQUIRED_MAJOR" "$REQUIRED_MINOR"

    PYTHON_COMMAND=""
    PYTHON_VERSION_OUTPUT=""

    # Try to find python3.9 first
    if command -v python3.9 &> /dev/null; then
        PYTHON_COMMAND="python3.9"
        PYTHON_VERSION_OUTPUT=$("$PYTHON_COMMAND" -V 2>&1)
    # If python3.9 not found, try python3 and check its version
    elif command -v python3 &> /dev/null; then
        TEMP_PYTHON_VERSION_OUTPUT=$("python3" -V 2>&1)
        TEMP_PYTHON_VERSION_NUM=$(echo "$TEMP_PYTHON_VERSION_OUTPUT" | awk '{print $2}')
        TEMP_PYTHON_MAJOR=$(echo "$TEMP_PYTHON_VERSION_NUM" | cut -d '.' -f 1)
        TEMP_PYTHON_MINOR=$(echo "$TEMP_PYTHON_VERSION_NUM" | cut -d '.' -f 2)

        if [ "$TEMP_PYTHON_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$TEMP_PYTHON_MINOR" -eq "$REQUIRED_MINOR" ]; then
            PYTHON_COMMAND="python3"
            PYTHON_VERSION_OUTPUT="$TEMP_PYTHON_VERSION_OUTPUT"
        fi
    fi

    # If a suitable Python command was found
    if [ -n "$PYTHON_COMMAND" ]; then
        PYTHON_VERSION_NUM=$(echo "$PYTHON_VERSION_OUTPUT" | awk '{print $2}')

        # Ensure version number is extracted before attempting to parse
        if [ -z "$PYTHON_VERSION_NUM" ]; then
             echo -e "${RED}${CROSS}${NC} (Could not parse Python version from output: $PYTHON_VERSION_OUTPUT)"
             return 1
        fi

        PYTHON_MAJOR=$(echo "$PYTHON_VERSION_NUM" | cut -d '.' -f 1)
        PYTHON_MINOR=$(echo "$PYTHON_VERSION_NUM" | cut -d '.' -f 2)

        # Perform integer comparison, ensuring variables are treated as integers
        if [ "$PYTHON_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$PYTHON_MINOR" -eq "$REQUIRED_MINOR" ]; then
            echo -e "${GREEN}${CHECKMARK}${NC} (Installed: $PYTHON_VERSION_NUM)"
            return 0
        else
            echo -e "${RED}${CROSS}${NC} (Installed: $PYTHON_VERSION_NUM, Required: $REQUIRED_MAJOR.$REQUIRED_MINOR.x)"
            return 1
        fi
    else
        echo -e "${RED}${CROSS}${NC} (Python 3.9 not found)"
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

# Perform check for PM2 startup service (systemd)
check_pm2_startup "PM2 startup service"

# Check Python version
check_python_version "$REQUIRED_PYTHON_MAJOR_VERSION" "$REQUIRED_PYTHON_MINOR_VERSION"

# Perform checks for additional applications
check_command "feh" "feh installation"
check_command "vlc" "VLC installation"
check_command "mpg321" "mpg321 installation"
check_command "unzip" "unzip installation"

echo "--------------------------"

