#/bin/sh

set -x
set -e

SOURCE_DIR="$1"

OPENSSL_DIR="$2"
JPEG_DIR="$3"
OPUS_DIR="$4"
FFMPEG_DIR="$5"
LIBVPX_DIR="$6"
OPENH264_DIR="$7"

BUILD_DIR="${PROJECT_DIR}/build/"

# Check if source directory exists and has CMakeLists.txt
if [ ! -f "$SOURCE_DIR/CMakeLists.txt" ]; then
    echo "ERROR: CMakeLists.txt not found in $SOURCE_DIR"
    echo "Attempting to initialize tg_owt submodule..."
    TG_OWT_PARENT="$(dirname "$SOURCE_DIR")/../.."
    (cd "$TG_OWT_PARENT" && git submodule update --init --force submodules/tg_owt)
    if [ ! -f "$SOURCE_DIR/CMakeLists.txt" ]; then
        echo "ERROR: Failed to initialize tg_owt submodule. CMakeLists.txt still not found."
        exit 1
    fi
fi

# Initialize tg_owt submodules recursively (crc32c, abseil-cpp, etc.)
# Check if .gitmodules exists to determine if this is a git repo with submodules
if [ -f "$SOURCE_DIR/.gitmodules" ]; then
    echo "Initializing tg_owt submodules..."
    (cd "$SOURCE_DIR" && git submodule update --init --recursive 2>&1 | head -20)
fi

rm -rf $BUILD_DIR || true
mkdir -p $BUILD_DIR || true

# Copy source to build directory (copy contents, not the directory itself)
if [ -d "$SOURCE_DIR" ]; then
    cp -R "$SOURCE_DIR"/* "$BUILD_DIR"/ 2>/dev/null || cp -R "$SOURCE_DIR"/. "$BUILD_DIR"/ 2>/dev/null || {
        echo "ERROR: Failed to copy source from $SOURCE_DIR to $BUILD_DIR"
        exit 1
    }
else
    echo "ERROR: Source directory $SOURCE_DIR does not exist"
    exit 1
fi

# Verify CMakeLists.txt exists in build directory
if [ ! -f "$BUILD_DIR/CMakeLists.txt" ]; then
    echo "ERROR: CMakeLists.txt not found in $BUILD_DIR after copying"
    exit 1
fi



LIBS=""
for ARCH in $ARCHS
do

pushd $BUILD_DIR

CURRENT_ARCH=$ARCH


OUT_DIR=$CURRENT_ARCH
mkdir -p $OUT_DIR || true
cd $OUT_DIR

cmake -G Ninja \
    -DCMAKE_OSX_ARCHITECTURES=$CURRENT_ARCH \
    -DTG_OWT_SPECIAL_TARGET=macstore \
    -DCMAKE_BUILD_TYPE=Release \
    -DNDEBUG=1 \
    -DTG_OWT_BUILD_AUDIO_BACKENDS=ON \
    -DTG_OWT_LIBJPEG_INCLUDE_PATH=$JPEG_DIR \
    -DTG_OWT_OPENSSL_INCLUDE_PATH=$OPENSSL_DIR \
    -DTG_OWT_OPUS_INCLUDE_PATH=$OPUS_DIR \
    -DTG_OWT_LIBVPX_INCLUDE_PATH=$LIBVPX_DIR \
    -DTG_OWT_OPENH264_INCLUDE_PATH=$OPENH264_DIR \
    -DTG_OWT_FFMPEG_INCLUDE_PATH=$FFMPEG_DIR ..

ninja
LIBS="$LIBS ${BUILD_DIR}$OUT_DIR/libtg_owt.a"
    # -DCMAKE_BUILD_TYPE=Debug

cd ..

done
#
LIB_PATH=${BUILD_DIR}webrtc
rm -rf $LIB_PATH || true
mkdir -p $LIB_PATH
lipo -create $LIBS -output "$LIB_PATH/libmac_framework_objc_static.a" || exit 1


#popd


#--developer_dir
