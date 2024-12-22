//
//  ContentView.swift
//  ET-YOLOX
//
//  Created by kikemori on 2024/12/22.
//

import Engine
import SwiftUI

func listAllResourcesInBundle(bundle: Bundle) {
    guard let resourcePath = bundle.resourcePath else {
        print("Could not find resource path for bundle: \(bundle)")
        return
    }

    do {
        let fileManager = FileManager.default
        let resourceContents = try fileManager.contentsOfDirectory(atPath: resourcePath)

        print("Resources in bundle: \(bundle.bundlePath)")
        for resource in resourceContents {
            print("- \(resource)")
        }
    } catch {
        print("Error while listing resources in bundle: \(error)")
    }
}

// すべてのロード可能なバンドルを取得
func listAllResourcesInAllBundles() {
    // メインバンドル
    print("\n[Main Bundle Resources]")
    listAllResourcesInBundle(bundle: .main)

    // フレームワークや動的ライブラリのバンドルを検索
    let bundles = Bundle.allBundles + Bundle.allFrameworks
    for bundle in bundles {
        print("\n[Bundle: \(bundle.bundleIdentifier ?? "Unknown")]")
        listAllResourcesInBundle(bundle: bundle)
    }
}

func listResourcesInEngineBundle() {
    // Main bundle から `Engine_Engine.bundle` のパスを取得
    guard let engineBundleURL = Bundle.main.url(forResource: "Engine_Engine", withExtension: "bundle") else {
        print("Engine_Engine.bundle not found in the main bundle.")
        return
    }

    // `Bundle` インスタンスを作成
    guard let engineBundle = Bundle(url: engineBundleURL) else {
        print("Could not load Engine_Engine.bundle.")
        return
    }

    // リソースディレクトリを列挙
    guard let resourcePath = engineBundle.resourcePath else {
        print("Could not find resource path in Engine_Engine.bundle.")
        return
    }

    do {
        let fileManager = FileManager.default
        let resourceContents = try fileManager.contentsOfDirectory(atPath: resourcePath)

        print("Resources in Engine_Engine.bundle:")
        for resource in resourceContents {
            print("- \(resource)")
        }
    } catch {
        print("Error while listing resources in Engine_Engine.bundle: \(error)")
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Tap Me") {
                // 実行
                let model_path = Bundle.main.path(forResource: "Engine_Engine.bundle/yolox_nano_coreml", ofType: "pte")
                let yolox = Yolox(modelPath: model_path!, inputSizes: [1, 3, 416, 416])
                yolox.loadModel()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
