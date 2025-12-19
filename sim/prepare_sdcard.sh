# SPDX-License-Identifier: MIT
#!/bin/bash
set -e

FIRMWARE_PATH="../software/tests/firmware/firmware.bin"
OUTPUT_FILE="sdcard.img"
HEADER_SIZE=0x1000
TOTAL_SIZE=$((32 * 1024 * 1024))  # 32 MB

echo "Preparing SD card image..."

# Check if firmware file exists
if [ ! -f "$FIRMWARE_PATH" ]; then
    echo "Error: Firmware file not found at $FIRMWARE_PATH"
    exit 1
fi

rm -f "$OUTPUT_FILE"

# 0x1000 bytes of zeros
echo "Creating header (0x1000 bytes of zeros)..."
dd if=/dev/zero of="$OUTPUT_FILE" bs=1 count=$((HEADER_SIZE)) 2>/dev/null

# firmware.bin
echo "Appending firmware.bin at offset 0x1000..."
cat "$FIRMWARE_PATH" >> "$OUTPUT_FILE"

# Pad to 32 MB
echo "Padding to 32 MB..."
truncate -s $TOTAL_SIZE "$OUTPUT_FILE"