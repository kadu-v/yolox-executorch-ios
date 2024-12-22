//
//  Yolox.swift
//  ET-YOLOX
//
//  Created by kikemori on 2024/12/22.
//
import AVFoundation
import CEngine
import os
import UIKit

class Yolox {
    var detector: OpaquePointer?
    var InputSizes: (Int, Int, Int, Int) // batch_size, channels, height, width
    let classes: [String]

    init(modelPath: String, inputSizes: [Int]) {
        InputSizes = (inputSizes[0], inputSizes[1], inputSizes[2], inputSizes[3])
        // Load class file
        classes = Yolox.loadClasses()

        // Convert Swift object to C pointer
        let inputSizesInt32 = inputSizes.map { Int32($0) }
        detector = CEngine.c_new(modelPath, inputSizesInt32, Int32(inputSizes.count))
    }

    /// Load from coco-text
    private static func loadClasses() -> [String] {
        let classesFilePath = Bundle.main.path(forResource: "Engine_Engine.bundle/coco-classes", ofType: "txt")
        let classesFileContent = try! String(contentsOfFile: classesFilePath!, encoding: .utf8)
        return classesFileContent.components(separatedBy: "\n")
    }

    public func getClass(clsIdx: Float) -> String {
        return classes[Int(clsIdx)]
    }

    public func getInputSizes() -> (Int, Int, Int, Int) {
        return InputSizes
    }

    public func loadModel() {
        if detector == nil {
            fatalError("Detector is not initialized")
        }
        let status = CEngine.c_init(detector)
        if status != 0 {
            fatalError("Failed to initialize the detector")
        } else {
            os_log("Detector is initialized successfully")
        }
    }

    private func preprocess(pixelBuffer: CVPixelBuffer, modelInputRange: CGRect) -> [Float]? {
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32BGRA)

        // measure the input image size
        let modelSize = CGSize(width: CGFloat(InputSizes.3), height: CGFloat(InputSizes.2))
        guard let thumbnail = pixelBuffer.resize(from: modelInputRange, to: modelSize)
        else {
            return nil
        }

        // Remove the alpha component from the image buffer to get the initialized `Data`.
        guard let rgbInput = thumbnail.rgbData()
        else {
            os_log("Failed to convert the image buffer to RGB data.")
            return nil
        }

        return rgbInput
    }

    private func invoke(input: inout [Float], len: Int) -> ([Float], Float, Float, Float) {
        let output = input.withUnsafeMutableBufferPointer { ptr in
            CEngine.c_detect(detector, ptr.baseAddress, Int32(len))
        }

        let data = output.objects
        let dataLength = output.objects_len
        let preprocessTime = output.pre_processing_time
        let forwardTime = output.foward_time
        let postprocessTime = output.post_processing_time
        let objects = [Float](UnsafeBufferPointer(start: data, count: Int(dataLength)))
        return (objects, preprocessTime, forwardTime, postprocessTime)
    }

    public func detect(pixelBuffer: CVPixelBuffer, modelInputRange: CGRect) -> ([Float], Float, Float, Float)? {
        guard var rgbInput = preprocess(pixelBuffer: pixelBuffer, modelInputRange: modelInputRange)
        else {
            return nil
        }
        let objects = invoke(input: &rgbInput, len: rgbInput.count)
        return objects
    }
}
