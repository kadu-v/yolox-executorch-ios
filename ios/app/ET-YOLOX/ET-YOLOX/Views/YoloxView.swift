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
    @State var tracking: Bool = false

    @State var trackingObj: String = "Person"
    let trackingObjs = ["Person": 0, "Car": 2, "Bicycle": 3]
    var body: some View {
        VStack {
            HostedYoloxViewController(aspectRatio: $aspectRatio,
                                      modelName: $modelName,
                                      modelPath: $modelPath,
                                      inputSizes: $inputSizes,
                                      tracking: $tracking,
                                      trackingObj: $trackingObj).ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: {
                        tracking = !tracking
                    }) {
                        Text("Tracking")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tracking ? .red : .blue)

                    VStack(spacing: 16) {
                        Picker("Choose an option", selection: $trackingObj) {
                            ForEach(trackingObjs.map { $0.key }, id: \.self) { obj in
                                Text(obj)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                }
                HStack {
                    Button(action: {
                        modelName = "Nano CoreML"
                        modelPath = "yolox_nano_coreml"
                        inputSizes = [1, 3, 416, 416]
                    }) {
                        Text("Nano CoreML")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(modelName == "Nano CoreML" ? .red : .blue)
                    Button(action: {
                        modelName = "Tiny CoreML"
                        modelPath = "yolox_tiny_coreml"
                        inputSizes = [1, 3, 416, 416]
                    }) {
                        Text("Tiny CorML")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(modelName == "Tiny CoreML" ? .red : .blue)
                    Button(action: {
                        modelName = "S CoreML"
                        modelPath = "yolox_s_coreml"
                        inputSizes = [1, 3, 640, 640]
                    }) {
                        Text("S CoreML")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(modelName == "S CoreML" ? .red : .blue)
                }
            }
            Spacer().frame(height: 40)
        }
    }
}

#Preview {
    YoloxView(aspectRatio: 1.0)
}
