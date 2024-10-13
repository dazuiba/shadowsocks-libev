# 定义变量
PROJECT_PATH="/Users/sam/dev/github/shadowsocks-libev"
BUILD_DIR="${PROJECT_PATH}/build/build"
PROJECT_FILE_PATH="${PROJECT_PATH}/build/shadowsocks-libev.xcodeproj"
CONFIGURATION="Debug"
clean=
FRAMEWORK_NAME="libsslocal"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UNIVERSAL_OUTPUTFOLDER="${SCRIPT_DIR}/Product/${CONFIGURATION}"
clean=
#clean=clean
# 清理之前的构建
rm -rf "${UNIVERSAL_OUTPUTFOLDER}"
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

# 构建 iOS 版本
xcodebuild -project "${PROJECT_FILE_PATH}" -target "${FRAMEWORK_NAME}" -sdk iphoneos -configuration ${CONFIGURATION} ${clean} build

# 构建 Simulator 版本
xcodebuild -project "${PROJECT_FILE_PATH}" -target "${FRAMEWORK_NAME}" -sdk iphonesimulator -configuration ${CONFIGURATION} ${clean} build

# 创建 XCFramework
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework" \
    -output "${UNIVERSAL_OUTPUTFOLDER}/${FRAMEWORK_NAME}.xcframework"

echo "XCFramework 已创建在 ${UNIVERSAL_OUTPUTFOLDER}/${FRAMEWORK_NAME}.xcframework"
