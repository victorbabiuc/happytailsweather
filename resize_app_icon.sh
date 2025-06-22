#!/bin/bash

# Happy Tails Weather App Icon Resizer
# This script resizes a 1024x1024 app icon to all required iOS sizes

SOURCE_ICON="happytails-icon-1024.png"
OUTPUT_DIR="AppIcons"

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Error: $SOURCE_ICON not found in current directory"
    echo "Please place your 1024x1024 app icon in this directory and name it '$SOURCE_ICON'"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🎨 Resizing app icon for iOS submission from $SOURCE_ICON..."

# Check if ImageMagick is available, otherwise use sips (macOS built-in)
if command -v convert &> /dev/null; then
    echo "Using ImageMagick for resizing..."
    
    # Resize to all required sizes
    convert "$SOURCE_ICON" -resize 1024x1024 "$OUTPUT_DIR/app-icon-1024.png"
    convert "$SOURCE_ICON" -resize 180x180 "$OUTPUT_DIR/app-icon-180.png"
    convert "$SOURCE_ICON" -resize 120x120 "$OUTPUT_DIR/app-icon-120.png"
    convert "$SOURCE_ICON" -resize 87x87 "$OUTPUT_DIR/app-icon-87.png"
    convert "$SOURCE_ICON" -resize 80x80 "$OUTPUT_DIR/app-icon-80.png"
    convert "$SOURCE_ICON" -resize 60x60 "$OUTPUT_DIR/app-icon-60.png"
    convert "$SOURCE_ICON" -resize 58x58 "$OUTPUT_DIR/app-icon-58.png"
    convert "$SOURCE_ICON" -resize 40x40 "$OUTPUT_DIR/app-icon-40.png"
    convert "$SOURCE_ICON" -resize 29x29 "$OUTPUT_DIR/app-icon-29.png"
    
else
    echo "Using macOS sips for resizing..."
    
    # Copy original
    cp "$SOURCE_ICON" "$OUTPUT_DIR/app-icon-1024.png"
    
    # Resize to all required sizes using sips
    sips -z 180 180 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-180.png"
    sips -z 120 120 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-120.png"
    sips -z 87 87 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-87.png"
    sips -z 80 80 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-80.png"
    sips -z 60 60 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-60.png"
    sips -z 58 58 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-58.png"
    sips -z 40 40 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-40.png"
    sips -z 29 29 "$SOURCE_ICON" --out "$OUTPUT_DIR/app-icon-29.png"
fi

echo "✅ App icons resized successfully!"
echo "📁 Icons saved in $OUTPUT_DIR/ directory:"
ls -la "$OUTPUT_DIR/"

echo ""
echo "📱 Next steps:"
echo "1. Open Xcode project"
echo "2. Navigate to Assets.xcassets → AppIcon"
echo "3. Drag and drop the appropriate icons to each slot"
echo "4. Update bundle identifier and display name"
echo "5. Build and test the app" 