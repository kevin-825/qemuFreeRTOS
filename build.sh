#!/bin/bash

# Function to check if jq is installed
check_and_install_jq() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        if [ "$(uname)" == "Linux" ]; then
            if [ -f /etc/debian_version ]; then
                sudo apt-get update && sudo apt-get install -y jq
            elif [ -f /etc/redhat-release ]; then
                sudo yum install -y epel-release && sudo yum install -y jq
            elif [ -f /etc/arch-release ]; then
                sudo pacman -Sy jq
            elif [ -f /etc/gentoo-release ]; then
                sudo emerge dev-util/jq
            fi
        elif [ "$(uname)" == "Darwin" ]; then
            brew install jq
        elif [ "$(uname)" == "FreeBSD" ]; then
            sudo pkg install jq
        else
            echo "Unsupported OS. Please install jq manually."
            exit 1
        fi
    fi
}

# Check and install jq if necessary
check_and_install_jq

# Function to display help message
display_help() {
    echo "Usage: $0 [-b <architecture> <build_type>] [-c <architecture>] [-h]"
    echo
    echo "Options:"
    echo "  -b <architecture> <build_type>    Build the project for the specified architecture and build type."
    echo "  -c <architecture>                 Clean the build directory or specific architecture subdirectory."
    echo "  -h                                Display this help message."
    echo
    echo "Architectures:"
    echo "  arm64, arm32, riscv64, riscv32, local"
    echo
    echo "Build Types:"
    echo "  release, debug"
    exit 0
}

# Function to clean the build directory
clean_build() {
    CONFIG_FILE="config.json"
    BUILD_DIR=$(jq -r ".build_dir" $CONFIG_FILE)
    ARCH=$1
    if [ -z "$ARCH" ]; then
        echo "Cleaning entire build directory: $BUILD_DIR"
        rm -rf $BUILD_DIR
        echo "Clean complete."
    else
        echo "Cleaning build directory for architecture: $ARCH"
        rm -rf $BUILD_DIR/$ARCH
        echo "Clean complete for architecture: $ARCH"
    fi
}

# Function to build the project
build_project() {
    ARCH=$1
    BUILD_TYPE=$2

    if [ -z "$ARCH" ] || [ -z "$BUILD_TYPE" ]; then
        echo "Usage: $0 -b <architecture> <build_type>"
        exit 1
    fi

    # Read JSON configuration
    CONFIG_FILE="config.json"
    BUILD_DIR=$(jq -r ".build_dir" $CONFIG_FILE)
    TARGET_NAME=$(jq -r ".target_name" $CONFIG_FILE)
    MAJOR_VERSION=$(jq -r ".version.major" $CONFIG_FILE)
    MINOR_VERSION=$(jq -r ".version.minor" $CONFIG_FILE)
    BUILD_NUMBER=$(jq -r ".version.build_number" $CONFIG_FILE)
    DEBUG=$(jq -r ".features.debug" $CONFIG_FILE)
    OPTIMIZATION=$(jq -r ".features.optimization" $CONFIG_FILE)
    CC=$(jq -r ".architectures[\"$ARCH\"].toolchain.CC" $CONFIG_FILE)
    AS=$(jq -r ".architectures[\"$ARCH\"].toolchain.AS" $CONFIG_FILE)
    SIZE=$(jq -r ".architectures[\"$ARCH\"].toolchain.SIZE" $CONFIG_FILE)
    CFLAGS=$(jq -r ".architectures[\"$ARCH\"].cflags" $CONFIG_FILE)
    LDFLAGS=$(jq -r ".architectures[\"$ARCH\"].ldflags" $CONFIG_FILE)
    ENV_PATH=$(jq -r ".architectures[\"$ARCH\"].env.PATH" $CONFIG_FILE)

    # Increment the build number
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    if [ $NEW_BUILD_NUMBER -gt 1000 ]; then
        NEW_BUILD_NUMBER=0
    fi

    # Construct the version variable
    VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${NEW_BUILD_NUMBER}"

    # Construct the target variable
    TARGET="${TARGET_NAME}_${ARCH}_v${VERSION}"

    # Update the build number in the JSON file
    jq ".version.build_number = $NEW_BUILD_NUMBER" $CONFIG_FILE > tmp.$$.json && mv tmp.$$.json $CONFIG_FILE

    # Export environment variables
    export PATH=$ENV_PATH

    # Include additional features in CFLAGS
    if [ "$DEBUG" = "true" ];then
        CFLAGS="$CFLAGS -g"
    fi
    if [ -n "$OPTIMIZATION" ];then
        CFLAGS="$CFLAGS -$OPTIMIZATION"
    fi

    # Adjust CFLAGS and LDFLAGS based on build type
    if [ "$BUILD_TYPE" = "release" ]; then
        CFLAGS="$CFLAGS -O3"
        LDFLAGS="$LDFLAGS -s"
    elif [ "$BUILD_TYPE" = "debug" ]; then
        CFLAGS="$CFLAGS -g -O0"
    fi

    # Invoke the Makefile
    make ARCH=$ARCH BUILD_TYPE=$BUILD_TYPE CC=$CC AS=$AS SIZE=$SIZE CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" BUILD_DIR=$BUILD_DIR TARGET=$TARGET
}

# Parse command line options
while getopts "b:c:h" opt; do
    case ${opt} in
        b)
            ARCH=$OPTARG
            BUILD_TYPE=$3
            if [ -z "$ARCH" ] || [ -z "$BUILD_TYPE" ]; then
                echo "Usage: $0 -b <architecture> <build_type>"
                exit 1
            fi
            BUILD=true
            ;;
        c)
            CLEAN_ARCH=$OPTARG
            CLEAN=true
            ;;
        h)
            display_help
            ;;
        *)
            display_help
            ;;
    esac
done

# Execute based on options
if [ "$CLEAN" = true ]; then
    clean_build $CLEAN_ARCH
fi
if [ "$BUILD" = true ]; then
    build_project $ARCH $BUILD_TYPE
fi

# Display help if no valid option provided
if [ -z "$BUILD" ] && [ -z "$CLEAN" ]; then
    display_help
fi
