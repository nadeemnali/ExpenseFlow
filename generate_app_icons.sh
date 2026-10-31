#!/bin/bash

# ExpenseFlow App Icon PNG Export Script
# This script converts the SVG logo to PNG files in all required sizes
# 
# Requirements:
#   - imagemagick (install with: brew install imagemagick)
#   - optipng (optional, for optimization: brew install optipng)
#
# Usage:
#   chmod +x generate_app_icons.sh
#   ./generate_app_icons.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SVG_FILE="$SCRIPT_DIR/Resources/AppIcon.svg"
OUTPUT_DIR="$SCRIPT_DIR/Resources/AppIcons"

# Check if SVG file exists
if [ ! -f "$SVG_FILE" ]; then
    echo -e "${RED}Error: AppIcon.svg not found at $SVG_FILE${NC}"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick not found. Install with: brew install imagemagick${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo -e "${BLUE}Creating app icons in: $OUTPUT_DIR${NC}\n"

# Define icon sizes
declare -a SIZES=(
    "1024:AppIcon-1024.png"
    "512:AppIcon-512.png"
    "256:AppIcon-256.png"
    "180:AppIcon-180.png"
    "167:AppIcon-167.png"
    "152:AppIcon-152.png"
    "120:AppIcon-120.png"
    "87:AppIcon-87.png"
    "80:AppIcon-80.png"
    "58:AppIcon-58.png"
    "40:AppIcon-40.png"
    "29:AppIcon-29.png"
)

# Generate each size
for size_pair in "${SIZES[@]}"
do
    IFS=':' read -r size filename <<< "$size_pair"
    output_file="$OUTPUT_DIR/$filename"
    
    echo -e "${BLUE}Generating ${size}×${size}...${NC} $filename"
    
    # Convert SVG to PNG using ImageMagick
    convert -background none \
            -density 300 \
            -resize "${size}x${size}" \
            "$SVG_FILE" \
            "$output_file"
    
    # Optimize if optipng is available
    if command -v optipng &> /dev/null; then
        optipng -quiet "$output_file"
    fi
    
    if [ -f "$output_file" ]; then
        size_bytes=$(ls -lh "$output_file" | awk '{print $5}')
        echo -e "${GREEN}  ✓ Created ($size_bytes)${NC}"
    else
        echo -e "${RED}  ✗ Failed${NC}"
    fi
done

echo -e "\n${GREEN}All icons generated successfully!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Open Xcode: ExpenseFlow.xcodeproj"
echo "2. Navigate to: Assets.xcassets"
echo "3. Right-click → New App Icon Set → Name: 'AppIcon'"
echo "4. Drag and drop all PNG files from: $OUTPUT_DIR"
echo "5. Verify each size is assigned correctly"
echo ""
echo -e "${BLUE}For help, see: LOGO_AND_SPLASH_SETUP.md${NC}"
