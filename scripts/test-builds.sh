    #!/bin/bash
    # Exit immediately if a command exits with a non-zero status.
    set -e

    echo "--- Cleaning ---"
    swift package clean
    # Alternatively, use: xcodebuild clean -scheme OpenPanel

    echo "--- Building for macOS ---"
    # Builds for the native architecture of your Mac (Intel or Apple Silicon)
    set -o pipefail && xcodebuild build -scheme OpenPanel-Swift-SDK -sdk macosx | xcpretty

    echo "--- Building for iOS Device (ARM64) ---"
    # Uses CODE_SIGNING_ALLOWED=NO to bypass code signing issues for compilation check
    set -o pipefail && xcodebuild build -scheme OpenPanel-Swift-SDK -sdk iphoneos CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO | xcpretty

    echo "--- Building for tvOS Device (ARM64) ---"
    set -o pipefail && xcodebuild build -scheme OpenPanel-Swift-SDK -sdk appletvos CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO | xcpretty

    # echo "--- Building for watchOS Device ---"
    # xcodebuild build -scheme OpenPanel -sdk watchos CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO | xcpretty

    echo "--- All targeted builds completed successfully! ---"
