#!/bin/bash
# Creates AppIcon.icns from a simple generated PNG using sips
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ICONSET_DIR="$PROJECT_DIR/build/AppIcon.iconset"
ICON_OUTPUT="$PROJECT_DIR/build/AppIcon.icns"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Generate a 1024x1024 base icon using a Python script (built-in on macOS)
python3 -c "
import subprocess, tempfile, os

# Create a simple SVG keyboard icon
svg = '''<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\">
  <defs>
    <linearGradient id=\"bg\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\">
      <stop offset=\"0%\" stop-color=\"#2D2D2D\"/>
      <stop offset=\"100%\" stop-color=\"#1A1A1A\"/>
    </linearGradient>
  </defs>
  <rect width=\"1024\" height=\"1024\" rx=\"220\" fill=\"url(#bg)\"/>
  <rect x=\"162\" y=\"312\" width=\"700\" height=\"400\" rx=\"40\" fill=\"#3A3A3A\" stroke=\"#555\" stroke-width=\"4\"/>
  <rect x=\"200\" y=\"350\" width=\"624\" height=\"324\" rx=\"20\" fill=\"#2A2A2A\"/>
  <!-- Row 1 -->
  <rect x=\"220\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F57644\"/>
  <rect x=\"282\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"344\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"406\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"468\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"530\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"592\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"654\" y=\"370\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"716\" y=\"370\" width=\"88\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <!-- Row 2 -->
  <rect x=\"220\" y=\"422\" width=\"72\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"302\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"364\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"426\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"488\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"550\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"612\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"674\" y=\"422\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"736\" y=\"422\" width=\"68\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <!-- Row 3 -->
  <rect x=\"220\" y=\"474\" width=\"82\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"312\" y=\"474\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"374\" y=\"474\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"436\" y=\"474\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"498\" y=\"474\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"560\" y=\"474\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"622\" y=\"474\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"684\" y=\"474\" width=\"120\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <!-- Row 4 -->
  <rect x=\"220\" y=\"526\" width=\"102\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"332\" y=\"526\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"394\" y=\"526\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"456\" y=\"526\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"518\" y=\"526\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"580\" y=\"526\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"642\" y=\"526\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"704\" y=\"526\" width=\"100\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <!-- Row 5 - space bar -->
  <rect x=\"220\" y=\"578\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"282\" y=\"578\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"344\" y=\"578\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"406\" y=\"578\" width=\"240\" height=\"42\" rx=\"6\" fill=\"#F5F5F5\"/>
  <rect x=\"656\" y=\"578\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"718\" y=\"578\" width=\"52\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <rect x=\"780\" y=\"578\" width=\"24\" height=\"42\" rx=\"6\" fill=\"#4A4A4A\"/>
  <!-- Sound waves -->
  <path d=\"M830 260 Q860 240 830 220\" stroke=\"#F57644\" stroke-width=\"8\" fill=\"none\" stroke-linecap=\"round\"/>
  <path d=\"M850 270 Q900 240 850 210\" stroke=\"#F57644\" stroke-width=\"8\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.7\"/>
  <path d=\"M870 280 Q940 240 870 200\" stroke=\"#F57644\" stroke-width=\"8\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.4\"/>
</svg>'''

# Write SVG to temp file
with open('/tmp/klick_icon.svg', 'w') as f:
    f.write(svg)
print('SVG icon created')
"

# Convert SVG to PNG using built-in qlmanage or rsvg-convert
if command -v rsvg-convert &>/dev/null; then
    rsvg-convert -w 1024 -h 1024 /tmp/klick_icon.svg -o /tmp/klick_icon_1024.png
elif command -v qlmanage &>/dev/null; then
    # qlmanage fallback - generate thumbnail
    qlmanage -t -s 1024 -o /tmp /tmp/klick_icon.svg 2>/dev/null
    mv /tmp/klick_icon.svg.png /tmp/klick_icon_1024.png 2>/dev/null || true
fi

# If we don't have a good converter, create a simple PNG with sips from a solid color
if [ ! -f /tmp/klick_icon_1024.png ]; then
    echo "No SVG converter found, creating placeholder icon..."
    # Create a 1024x1024 PNG using Python + CoreGraphics
    python3 -c "
import Quartz
import CoreGraphics

size = 1024
cs = CoreGraphics.CGColorSpaceCreateDeviceRGB()
ctx = CoreGraphics.CGBitmapContextCreate(None, size, size, 8, size * 4, cs, CoreGraphics.kCGImageAlphaPremultipliedLast)

# Dark background with rounded rect
CoreGraphics.CGContextSetRGBFillColor(ctx, 0.11, 0.11, 0.11, 1.0)
path = CoreGraphics.CGPathCreateWithRoundedRect((0, 0, size, size), 220, 220, None)
CoreGraphics.CGContextAddPath(ctx, path)
CoreGraphics.CGContextFillPath(ctx)

# Keyboard body
CoreGraphics.CGContextSetRGBFillColor(ctx, 0.23, 0.23, 0.23, 1.0)
path = CoreGraphics.CGPathCreateWithRoundedRect((162, 312, 700, 400), 40, 40, None)
CoreGraphics.CGContextAddPath(ctx, path)
CoreGraphics.CGContextFillPath(ctx)

# Accent key
CoreGraphics.CGContextSetRGBFillColor(ctx, 0.96, 0.46, 0.27, 1.0)
path = CoreGraphics.CGPathCreateWithRoundedRect((220, 610, 52, 42), 6, 6, None)
CoreGraphics.CGContextAddPath(ctx, path)
CoreGraphics.CGContextFillPath(ctx)

# White keys
CoreGraphics.CGContextSetRGBFillColor(ctx, 0.96, 0.96, 0.96, 1.0)
for x in range(302, 680, 62):
    path = CoreGraphics.CGPathCreateWithRoundedRect((x, 540, 52, 42), 6, 6, None)
    CoreGraphics.CGContextAddPath(ctx, path)
    CoreGraphics.CGContextFillPath(ctx)

img = CoreGraphics.CGBitmapContextCreateImage(ctx)
url = CoreGraphics.CFURLCreateWithFileSystemPath(None, '/tmp/klick_icon_1024.png', CoreGraphics.kCFURLPOSIXPathStyle, False)
dest = CoreGraphics.CGImageDestinationCreateWithURL(url, 'public.png', 1, None)
CoreGraphics.CGImageDestinationAddImage(dest, img, None)
CoreGraphics.CGImageDestinationFinalize(dest)
print('PNG icon created')
"
fi

BASE="/tmp/klick_icon_1024.png"

if [ ! -f "$BASE" ]; then
    echo "Error: Could not generate icon. Please provide a 1024x1024 PNG at $BASE"
    exit 1
fi

# Generate all required sizes
declare -a SIZES=(16 32 64 128 256 512 1024)
for size in "${SIZES[@]}"; do
    sips -z "$size" "$size" "$BASE" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null 2>&1
done

# Create @2x variants
cp "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# Remove non-standard sizes
rm -f "$ICONSET_DIR/icon_64x64.png"
rm -f "$ICONSET_DIR/icon_1024x1024.png"

# Generate icns
iconutil -c icns "$ICONSET_DIR" -o "$ICON_OUTPUT"
echo "Created $ICON_OUTPUT"
