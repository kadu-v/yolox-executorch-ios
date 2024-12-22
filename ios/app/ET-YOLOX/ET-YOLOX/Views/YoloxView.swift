//
//  YoloxView.swift
//  ET-YOLOX
//
//  Created by kikemori on 2024/12/22.
//

import Foundation
import SwiftUI

struct YoloxView: View {
    @State var aspectRatio: Float = 1.0
    @State var modelName: String = "Nano CoreML"
    @State var modelPath: String = "yolox_tiny_coreml"
    @State var inputSizes: [Int] = [1, 3, 416, 416]
    var body: some View {
        VStack {
            HostedYoloxViewController(aspectRatio: $aspectRatio,
                                      modelName: $modelName,
                                      modelPath: $modelPath,
                                      inputSizes: $inputSizes).ignoresSafeArea()

            HStack {
                Button(action: {
                    modelName = "Nano CoreML"
                    modelPath = "yolox_nano_coreml"
                    inputSizes = [1, 3, 416, 416]
                }) {
                    Text("Nano CoreML")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                Button(action: {
                    modelName = "Tiny CoreML"
                    modelPath = "yolox_tiny_coreml"
                    inputSizes = [1, 3, 416, 416]
                }) {
                    Text("Tiny CorML")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                Button(action: {
                    modelName = "S CoreML"
                    modelPath = "yolox_s_coreml"
                    inputSizes = [1, 3, 640, 640]
                }) {
                    Text("S CoreML")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            Spacer().frame(height: 40)
        }
    }
}

#Preview {
    YoloxView(aspectRatio: 1.0)
}
