#!/bin/bash

# --- Configuration ---
# IMPORTANT: Replace with the actual URL of the zip file containing the build.
DEPLOY_URL=https://github.com/inf-projects/greenhome-sbc-deploy/releases/download/v1.5.0-470710/sbc-server_1.5.0_470710.zip

# The target directory where your application code will be deployed.
TARGET_DIR="$HOME/sbc-server"

# The name of the PM2 process will be read from the pm2.json file in the TARGET_DIR.
# No need to set PM2_PROCESS_NAME here anymore.

# Create a temporary directory for download and extraction
TEMP_DIR=$(mktemp -d)

# Color Codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}--- Starting Deployment Script ---${NC}"

# --- Note on Prerequisites ---
# Prerequisites (curl, unzip, pm2, jq) should be checked using the separate
# system_check.sh script before running this deployment script.
echo -e "${YELLOW}Assuming prerequisites (curl, unzip, pm2, jq) are met (checked by system_check.sh).${NC}"

# --- Step 1: Ensure target directory exists ---
echo -e "${YELLOW}Ensuring target directory exists: ${TARGET_DIR}${NC}"
mkdir -p "$TARGET_DIR"
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}FAIL${NC}: Could not create target directory ${TARGET_DIR}"
    # Clean up temp directory before exiting
    echo -e "${YELLOW}Cleaning up temporary directory: ${TEMP_DIR}${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}OK${NC}: Target directory exists."

# --- Step 2: Show current version (if package.json exists) ---
if [ -f "$TARGET_DIR/package.json" ]; then
    echo -e "${YELLOW}Current deployed version:${NC}"
    # Use jq to safely read name and version
    # Check if jq is installed before attempting to use it
    if command -v jq &> /dev/null; then
        jq -r '.name + " v" + .version' "$TARGET_DIR/package.json" 2>/dev/null || echo "Could not read version from package.json"
    else
        echo "jq not found. Cannot read version from package.json."
    fi
else
    echo -e "${YELLOW}No existing deployment found in ${TARGET_DIR} or package.json not found.${NC}"
fi
echo "" # Add a newline for spacing

# --- Step 3: Download the new build ---
ZIP_FILE="$TEMP_DIR/build.zip"
echo -e "${YELLOW}Downloading new build from ${DEPLOY_URL} to ${ZIP_FILE}${NC}"
# Use -L to follow redirects, -o to specify output file
if ! curl -L -o "$ZIP_FILE" "$DEPLOY_URL"; then
    echo -e "${RED}FAIL${NC}: Download failed. Please check the URL and network connection."
    # Clean up temp directory before exiting
    echo -e "${YELLOW}Cleaning up temporary directory: ${TEMP_DIR}${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}OK${NC}: Download successful."

# --- Step 4: Extract the build ---
EXTRACT_DIR="$TEMP_DIR/extracted"
echo -e "${YELLOW}Extracting build to ${EXTRACT_DIR}${NC}"
mkdir -p "$EXTRACT_DIR"
# Use -q for quiet mode, -d to specify destination directory
if ! unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"; then
    echo -e "${RED}FAIL${NC}: Extraction failed. Is the downloaded file a valid zip archive?"
    # Clean up temp directory before exiting
    echo -e "${YELLOW}Cleaning up temporary directory: ${TEMP_DIR}${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}OK${NC}: Extraction successful."

# --- Step 5: Deploy the new build (Override current code) ---
echo -e "${YELLOW}Deploying new build to ${TARGET_DIR}${NC}"
# Copy contents from extracted dir to target dir, overwriting existing files.
# Using `.` at the end of the source directory copies the contents *of* the directory,
# including hidden files, rather than the directory itself.
# Note: This will overwrite ALL files/folders in TARGET_DIR that exist in EXTRACT_DIR.
# If you have data files in TARGET_DIR that are NOT in the zip and should be preserved,
# this copy method is safe. If data files *are* in the zip but should *not* overwrite
# existing data files in TARGET_DIR, a more complex copy/merge strategy is needed.
if ! cp -r "$EXTRACT_DIR/." "$TARGET_DIR/"; then
    echo -e "${RED}FAIL${NC}: Deployment failed (file copy error). Check permissions."
    # Clean up temp directory before exiting
    echo -e "${YELLOW}Cleaning up temporary directory: ${TEMP_DIR}${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}OK${NC}: Deployment successful."

# --- Step 6: Clean up temporary directory ---
echo -e "${YELLOW}Cleaning up temporary directory: ${TEMP_DIR}${NC}"
rm -rf "$TEMP_DIR"
echo -e "${GREEN}OK${NC}: Temporary directory cleaned."

# --- Step 7: Determine PM2 Process Name from pm2.json and Restart/Start Service ---
PM2_JSON_PATH="$TARGET_DIR/pm2.json"
echo -e "${YELLOW}Determining PM2 process name from ${PM2_JSON_PATH}${NC}"

if [ -f "$PM2_JSON_PATH" ]; then
    # Use jq to extract the 'name' field from pm2.json
    # Assuming pm2.json is an array of processes, we'll take the name of the first one.
    # If it's a single process object, jq '.name' will work.
    # We'll try the array format first, then the object format.
    # Added check for jq before using it
    if command -v jq &> /dev/null; then
        PM2_PROCESS_NAME=$(jq -r '.[0].name' "$PM2_JSON_PATH" 2>/dev/null)

        # If the array format failed, try the single object format
        if [ -z "$PM2_PROCESS_NAME" ] || [ "$PM2_PROCESS_NAME" = "null" ]; then
            PM2_PROCESS_NAME=$(jq -r '.name' "$PM2_JSON_PATH" 2>/dev/null)
        fi
    else
        echo -e "${RED}FAIL${NC}: 'jq' command not found. Cannot determine PM2 process name from pm2.json."
        exit 1
    fi


    if [ -z "$PM2_PROCESS_NAME" ] || [ "$PM2_PROCESS_NAME" = "null" ]; then
        echo -e "${RED}FAIL${NC}: Could not determine PM2 process name from ${PM2_JSON_PATH}. Make sure the 'name' field is present."
        exit 1 # Exit with error code
    end
