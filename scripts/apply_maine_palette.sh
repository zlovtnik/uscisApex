#!/bin/bash
# ============================================================
# Apply "Maine Professional" palette to app-styles.css
# Replaces the old "New England Coastal" palette colors
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CSS_FILE="${1:-${SCRIPT_DIR}/../shared_components/files/app-styles.css}"

# Portable in-place sed: works on both macOS (BSD) and Linux (GNU)
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    # GNU sed
    sed -i "$@"
  else
    # BSD sed (macOS)
    sed -i '' "$@"
  fi
}

echo "=== Applying Maine Professional palette ==="

# Restore from backup if exists
if [ -f "${CSS_FILE}.bak" ]; then
  cp "${CSS_FILE}.bak" "$CSS_FILE"
  echo "Restored from backup"
else
  cp "$CSS_FILE" "${CSS_FILE}.bak"
  echo "Created backup"
fi

# ================================================================
# Core Hex Color Replacements
# ================================================================

# Primary: Dark green → Coastal Navy
sed_inplace 's/#1a3a2e/#082E58/g' "$CSS_FILE"

# Primary light: Dark blue → Lighter Navy
sed_inplace 's/#0d2b3e/#0A3D73/g' "$CSS_FILE"

# Secondary: Blue-gray → Pine Green
sed_inplace 's/#4a5f7f/#004832/g' "$CSS_FILE"

# Secondary dark: Deep blue → Deep Pine
sed_inplace 's/#1c2841/#002E20/g' "$CSS_FILE"

# Accent: Cool blue → Resurgam Yellow
sed_inplace 's/#789ca8/#FFE84F/g' "$CSS_FILE"

# Danger shades
sed_inplace 's/#8b2e2e/#8B1A1A/g' "$CSS_FILE"
sed_inplace 's/#a84a3d/#B22222/g' "$CSS_FILE"

# Warning/pending → Teakwood
sed_inplace 's/#9d5a3c/#6F513E/g' "$CSS_FILE"
sed_inplace 's/#b87a5a/#8B6914/g' "$CSS_FILE"

# Success shade
sed_inplace 's/#2a5e4a/#006B4C/g' "$CSS_FILE"

# Neutral backgrounds → Fog & White
sed_inplace 's/#dde0d8/#F4F7F6/g' "$CSS_FILE"
sed_inplace 's/#edeee9/#FFFFFF/g' "$CSS_FILE"
sed_inplace 's/#f5f4f0/#F8FAF9/g' "$CSS_FILE"
sed_inplace 's/#f5f7f4/#F8FAF9/g' "$CSS_FILE"
sed_inplace 's/#dddfd9/#EDF0EF/g' "$CSS_FILE"
sed_inplace 's/#d2d5cd/#E8ECEB/g' "$CSS_FILE"

# Neutral grays
sed_inplace 's/#e8eae6/#FFFFFF/g' "$CSS_FILE"
sed_inplace 's/#b8bdb3/#CCD3D1/g' "$CSS_FILE"
sed_inplace 's/#7a8279/#8A9490/g' "$CSS_FILE"
sed_inplace 's/#5a6674/#6F513E/g' "$CSS_FILE"
sed_inplace 's/#4d4437/#5A4A3C/g' "$CSS_FILE"
sed_inplace 's/#3d4550/#3D3028/g' "$CSS_FILE"

# Login page deep blacks → deep navy
sed_inplace 's/#040d09/#020E1F/g' "$CSS_FILE"
sed_inplace 's/#03080f/#020A14/g' "$CSS_FILE"
sed_inplace 's/#060a14/#030D1A/g' "$CSS_FILE"

# Misc login shades
sed_inplace 's/#1a2530/#082E58/g' "$CSS_FILE"
sed_inplace 's/#2a3540/#0A3D73/g' "$CSS_FILE"
sed_inplace 's/#10261e/#082040/g' "$CSS_FILE"

echo "=== Hex replacements done ==="

# ================================================================
# RGBA Color Replacements
# ================================================================

# Primary rgba: (26, 58, 46) → (8, 46, 88)
sed_inplace 's/rgba(26, 58, 46,/rgba(8, 46, 88,/g' "$CSS_FILE"

# Secondary rgba: (74, 95, 127) → (0, 72, 50)
sed_inplace 's/rgba(74, 95, 127,/rgba(0, 72, 50,/g' "$CSS_FILE"

# Accent rgba: (120, 156, 168) → (0, 72, 50) [pine green for subtle glows]
sed_inplace 's/rgba(120, 156, 168,/rgba(0, 72, 50,/g' "$CSS_FILE"

# Old primary-light rgba
sed_inplace 's/rgba(13, 43, 62,/rgba(10, 61, 115,/g' "$CSS_FILE"

# Pending/warning rgba
sed_inplace 's/rgba(157, 90, 60,/rgba(111, 81, 62,/g' "$CSS_FILE"

# Danger shade rgba
sed_inplace 's/rgba(168, 74, 61,/rgba(178, 34, 34,/g' "$CSS_FILE"

# Warning shade rgba
sed_inplace 's/rgba(184, 122, 90,/rgba(139, 105, 20,/g' "$CSS_FILE"

# Success shade rgba
sed_inplace 's/rgba(42, 94, 74,/rgba(0, 107, 76,/g' "$CSS_FILE"

# Deep background rgba
sed_inplace 's/rgba(16, 38, 30,/rgba(8, 32, 64,/g' "$CSS_FILE"
sed_inplace 's/rgba(15, 22, 38,/rgba(0, 46, 32,/g' "$CSS_FILE"
sed_inplace 's/rgba(8, 25, 38,/rgba(8, 32, 64,/g' "$CSS_FILE"
sed_inplace 's/rgba(90, 102, 116,/rgba(111, 81, 62,/g' "$CSS_FILE"

echo "=== RGBA replacements done ==="

# ================================================================
# Update header comment
# ================================================================

sed_inplace 's/NEW ENGLAND COASTAL EDITION/MAINE PROFESSIONAL EDITION/g' "$CSS_FILE"
sed_inplace 's/New England Coastal Palette/Maine Professional Palette/g' "$CSS_FILE"
sed_inplace 's/New England Coastal/Maine Professional/g' "$CSS_FILE"
sed_inplace 's/Version: 3.0.0/Version: 4.0.0/g' "$CSS_FILE"
sed_inplace 's/February 4, 2026/February 8, 2026/g' "$CSS_FILE"
sed_inplace 's/Glassmorphism, Animations/Inter Font, Maine Palette, WCAG AA/g' "$CSS_FILE"
sed_inplace 's/Weathered & Natural/Fog \& Granite/g' "$CSS_FILE"
sed_inplace 's/Coastal Inspired/Maine Professional/g' "$CSS_FILE"

echo "=== Comment updates done ==="
echo "=== Maine Professional palette applied successfully ==="
