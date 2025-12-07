#!/bin/bash

# Script to rename project from "rever" to "soteria"
# WARNING: Close Xcode before running this script!

set -e

OLD_NAME="rever"
NEW_NAME="soteria"
OLD_NAME_CAPITALIZED="Rever"
NEW_NAME_CAPITALIZED="Soteria"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
NEW_PROJECT_DIR="$PARENT_DIR/$NEW_NAME"

echo "🔄 Renaming project from $OLD_NAME to $NEW_NAME..."
echo "📁 Current directory: $SCRIPT_DIR"
echo "📁 New directory: $NEW_PROJECT_DIR"
echo ""
read -p "⚠️  Make sure Xcode is CLOSED. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Step 1: Rename the main project folder
echo "📦 Step 1: Renaming project folder..."
cd "$PARENT_DIR"
if [ -d "$NEW_NAME" ]; then
    echo "❌ Error: $NEW_NAME directory already exists!"
    exit 1
fi
mv "$OLD_NAME" "$NEW_NAME"
echo "✅ Folder renamed"

# Step 2: Rename Xcode project file
echo "📦 Step 2: Renaming Xcode project..."
cd "$NEW_PROJECT_DIR"
if [ -d "$OLD_NAME.xcodeproj" ]; then
    mv "$OLD_NAME.xcodeproj" "$NEW_NAME.xcodeproj"
    echo "✅ Xcode project renamed"
fi

# Step 3: Rename workspace if it exists
if [ -d "$OLD_NAME.xcworkspace" ]; then
    mv "$OLD_NAME.xcworkspace" "$NEW_NAME.xcworkspace"
    echo "✅ Workspace renamed"
fi

# Step 4: Update project.pbxproj file
echo "📦 Step 3: Updating project.pbxproj..."
if [ -f "$NEW_NAME.xcodeproj/project.pbxproj" ]; then
    # Use sed to replace references (be careful with these)
    sed -i '' "s/$OLD_NAME\.app/$NEW_NAME.app/g" "$NEW_NAME.xcodeproj/project.pbxproj"
    sed -i '' "s/Pods-$OLD_NAME/Pods-$NEW_NAME/g" "$NEW_NAME.xcodeproj/project.pbxproj"
    sed -i '' "s/Pods_$OLD_NAME/Pods_$NEW_NAME/g" "$NEW_NAME.xcodeproj/project.pbxproj"
    sed -i '' "s/$OLD_NAME\.xcodeproj/$NEW_NAME.xcodeproj/g" "$NEW_NAME.xcodeproj/project.pbxproj"
    sed -i '' "s/path = $OLD_NAME/path = $NEW_NAME/g" "$NEW_NAME.xcodeproj/project.pbxproj"
    echo "✅ project.pbxproj updated"
fi

# Step 5: Update workspace contents if it exists
if [ -f "$NEW_NAME.xcworkspace/contents.xcworkspacedata" ]; then
    sed -i '' "s/$OLD_NAME\.xcodeproj/$NEW_NAME.xcodeproj/g" "$NEW_NAME.xcworkspace/contents.xcworkspacedata"
    echo "✅ Workspace contents updated"
fi

# Step 6: Update Podfile
if [ -f "Podfile" ]; then
    sed -i '' "s/target '$OLD_NAME'/target '$NEW_NAME'/g" Podfile
    sed -i '' "s/target \"$OLD_NAME\"/target \"$NEW_NAME\"/g" Podfile
    echo "✅ Podfile updated"
    echo "⚠️  You'll need to run 'pod install' after this"
fi

echo ""
echo "✅ Project renamed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Open $NEW_NAME.xcworkspace (or $NEW_NAME.xcodeproj) in Xcode"
echo "2. In Xcode, go to Project Settings → General"
echo "3. Update 'Display Name' to 'SOTERIA'"
echo "4. Update 'Product Name' to 'soteria'"
echo "5. If using CocoaPods, run: cd $NEW_PROJECT_DIR && pod install"
echo "6. Clean build folder (Cmd+Shift+K) and rebuild"
echo ""
echo "🎉 Done!"

