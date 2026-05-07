#!/bin/bash
set -e

echo "========================================="
echo "  BookReader iOS 构建脚本"
echo "========================================="

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_DIR="$PROJECT_DIR/output"

rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cd "$PROJECT_DIR/BookReader"

# Step 1: Resolve Swift Package dependencies
echo "📦 正在解析依赖..."
swift package resolve 2>/dev/null || echo "  ⚠️ 使用本地依赖"

# Step 2: Build with Xcode
echo "🔨 正在编译..."
xcodebuild \
    -project ../BookReader.xcodeproj/project.pbxproj \
    -scheme BookReader \
    -configuration Release \
    -sdk iphoneos \
    -derivedDataPath "../build/DerivedData" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build \
    | grep -E "(error:|warning:|BUILD|Compiling|Linking)" || true

# Step 3: Find and package IPA
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "BookReader.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ 未找到 .app 文件，尝试备用方案..."
    # Try to find any app in build output
    APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d 2>/dev/null | head -1)
fi

if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
    echo "✅ 找到 App: $APP_PATH"

    # Create IPA structure
    TEMP_IPA="/tmp/bookreader-ipa-$$"
    mkdir -p "$TEMP_IPA/Payload"
    cp -R "$APP_PATH" "$TEMP_IPA/Payload/"

    # Create unsigned IPA
    cd "$TEMP_IPA"
    zip -rq "$OUTPUT_DIR/BookReader-unsigned.ipa" Payload/
    rm -rf "$TEMP_IPA"

    echo "========================================="
    echo "✅ 构建成功！"
    echo ""
    echo "📦 输出文件:"
    echo "   $OUTPUT_DIR/BookReader-unsigned.ipa"
    echo ""
    echo "📊 文件大小: $(du -h "$OUTPUT_DIR/BookReader-unsigned.ipa" | cut -f1)"
    echo "========================================="
else
    echo "❌ 构建失败：未找到 App 包"
    exit 1
fi
