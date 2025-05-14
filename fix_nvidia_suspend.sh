#!/bin/bash
set -e

CONFIG_PATH="/etc/modprobe.d/nvidia-power-management.conf"
CONFIG_LINE="options nvidia NVreg_PreserveVideoMemoryAllocations=1"

echo "🔍 Checking for NVIDIA GPU..."
if ! lspci | grep -iq nvidia; then
    echo "❌ No NVIDIA GPU detected. Exiting."
    exit 0
fi

echo "✅ NVIDIA GPU detected."

echo "🔍 Checking for proprietary NVIDIA driver..."
if ! lsmod | grep -q nvidia; then
    echo "⚠️ NVIDIA kernel module not loaded. Are you using the proprietary driver?"
    echo "ℹ️ If not installed, run: sudo dnf install akmod-nvidia"
    exit 1
fi

echo "✅ NVIDIA driver is active."

# Check if the config file already exists and contains the expected line
if [[ -f "$CONFIG_PATH" ]] && grep -Fxq "$CONFIG_LINE" "$CONFIG_PATH"; then
    echo "✅ Configuration already present in $CONFIG_PATH. No changes needed."
    exit 0
fi

echo "⚙️ Applying configuration to $CONFIG_PATH..."

# Write or overwrite config file with the correct setting
echo "$CONFIG_LINE" | sudo tee "$CONFIG_PATH" > /dev/null

echo "🔄 Regenerating initramfs (this may take a moment)..."
sudo dracut -f

echo "✅ Configuration applied successfully."
echo "🚀 Please reboot your system for changes to take effect."
