#!/bin/zsh
SCRIPT_DIR=$(cd $(dirname $0); pwd)

FRAMEWORK_NAME=CEngine
CRATE_NAME=engine
TARGETS=(
    "aarch64-apple-ios"
    "aarch64-apple-ios-sim"
)


function println() {
    echo "#####################################################################"
    echo "$1"
    echo "#####################################################################"
}

function build_framework() {
    local target=$1

    # build framework
    println "Build framework for $target"
    (
        cd $SCRIPT_DIR/../engine
        cargo build --features apple --target $target --release
    )

    # copy framework from base 
    println "Copy framework from base"
    mkdir -p $SCRIPT_DIR/../ios/swift-pkg/frameworks/$target/CEngine.framework
    cp -r $SCRIPT_DIR/../ios/swift-pkg/frameworks/base/* $SCRIPT_DIR/../ios/swift-pkg/frameworks/$target/CEngine.framework
    cp -r $SCRIPT_DIR/../engine/target/$target/release/lib$CRATE_NAME.a $SCRIPT_DIR/../ios/swift-pkg/frameworks/$target/CEngine.framework/CEngine
}


(
    cd $SCRIPT_DIR/../engine
    for target in $TARGETS; do
        build_framework $target
    done

    println "Build XCframework"
    xcodebuild -create-xcframework \
        -framework $SCRIPT_DIR/../ios/swift-pkg/frameworks/aarch64-apple-ios/CEngine.framework \
        -framework $SCRIPT_DIR/../ios/swift-pkg/frameworks/aarch64-apple-ios-sim/CEngine.framework \
        -output $SCRIPT_DIR/../ios/swift-pkg/Engine/xcframework/CEngine.xcframework
)