#!/bin/bash

# ============================
# apt-lp Smart Installer
# ============================

# 1. Ubuntu check
if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
    echo "ERROR: This installer only supports Ubuntu."
    exit 1
fi

echo "Detected Ubuntu system."

# 2. Preferred path + auto-detect fallback
PREFERRED="/usr/local/bin"

echo "Searching for suitable install directory..."

INSTALL_PATH=""

# First try preferred path, but only if:
# - it exists
# - it is writable (or can be sudo-writable)
if [ -d "$PREFERRED" ]; then
    if [ -w "$PREFERRED" ] || sudo test -w "$PREFERRED"; then
        INSTALL_PATH="$PREFERRED/apt-lp"
        echo "Using preferred install path: $PREFERRED"
    fi
fi

# If not selected yet → dynamically scan PATH
if [ -z "$INSTALL_PATH" ]; then
    IFS=':' read -ra PATH_DIRS <<< "$PATH"
    for DIR in "${PATH_DIRS[@]}"; do
        # Skip empty entries from PATH
        [ -z "$DIR" ] && continue

        # Only use directories that exist
        if [ -d "$DIR" ]; then
            # Check write permission or sudo write permission
            if [ -w "$DIR" ] || sudo test -w "$DIR"; then
                INSTALL_PATH="$DIR/apt-lp"
                echo "Found writable PATH directory: $DIR"
                break
            fi
        fi
    done
fi

# If still not found → error out
if [ -z "$INSTALL_PATH" ]; then
    echo "ERROR: No writable directory found in PATH."
    echo "PATH was: $PATH"
    exit 1
fi

echo "apt-lp will be installed to: $INSTALL_PATH"

# 3. Write the apt-lp script to chosen location
sudo bash -c "cat > $INSTALL_PATH" << 'EOF'
#!/bin/bash

# ============================
# apt-lp (Ubuntu patch summary)
# ============================

# Refresh package lists (quiet unless errors)
echo "Updating package lists..."
sudo apt update -qq
UPDATE_STATUS=$?

if [ $UPDATE_STATUS -ne 0 ]; then
    echo "WARNING: apt update failed. Results may be outdated."
fi

# Collect list of all package upgrades
UPGRADABLE=$(apt-get -s dist-upgrade | grep '^Inst ' | sed '/^$/d')
TOTAL_UPDATES=$(echo "$UPGRADABLE" | sed '/^$/d' | wc -l)

# Security updates only
SECURITY_UPDATES_LIST=$(echo "$UPGRADABLE" | grep -i security | sed '/^$/d')
SECURITY_UPDATES_COUNT=$(echo "$SECURITY_UPDATES_LIST" | sed '/^$/d' | wc -l)

########################################
# DISPLAY OUTPUT
########################################

echo "==================== ALL PATCHES AVAILABLE ===================="
if [ "$TOTAL_UPDATES" -eq 0 ]; then
    echo "(no patches available)"
else
    echo "$UPGRADABLE"
fi
echo

echo "==================== SECURITY PATCHES ONLY ===================="
if [ "$SECURITY_UPDATES_COUNT" -eq 0 ]; then
    echo "(no security patches available)"
else
    echo "$SECURITY_UPDATES_LIST"
fi
echo

echo "==================== SUMMARY ===================="
echo "Total patches available:     $TOTAL_UPDATES"
echo "Security patches available:  $SECURITY_UPDATES_COUNT"
echo "--------------------------------------------------"
echo "Non-security patches:        $((TOTAL_UPDATES - SECURITY_UPDATES_COUNT))"
echo "=================================================="
EOF

# 4. Permissions
sudo chmod +x "$INSTALL_PATH"

echo
echo "Installation successful!"
echo "You can now run: apt-lp"
