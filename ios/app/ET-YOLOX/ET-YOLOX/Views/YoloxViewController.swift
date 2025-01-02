//
//  YoloxViewController.swift
//  ET-YOLOX
//
//  Created by kikemori on 2024/12/22.
//

import Accelerate
import AVFoundation
import os
import SwiftUI
import UIKit

class YoloxViewController: ViewController {
    var detectionLayer: CALayer!
    var detector: Yolox

    let trackingObjs = ["Person": 0, "Car": 2, "Bicycle": 3]

    // モデルのアスペクト比
    @Binding var aspectRatio: Float
    @Binding var modelName: String
    @Binding var modelPath: String
    @Binding var inputSizes: [Int]

    @Binding var tracking: Bool
    @Binding var trackingObj: String

    init(aspectRatio: Binding<Float>,
         modelName: Binding<String>,
         modelPath: Binding<String>,
         inputSizes: Binding<[Int]>,
         tracking: Binding<Bool>,
         trackingObj: Binding<String>)
    {
        _aspectRatio = aspectRatio
        _modelName = modelName
        _modelPath = modelPath
        _inputSizes = inputSizes
        _tracking = tracking
        _trackingObj = trackingObj

        // モデルの初期化
        let modelPath = Bundle.main.path(forResource: "Engine_Engine.bundle/" + modelPath.wrappedValue, ofType: "pte")!
        detector = Yolox(modelPath: modelPath, inputSizes: inputSizes.wrappedValue)
        detector.loadModel()
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupLayers() {
        // 検出結果を表示させるレイヤーを作成
        let width = previewBounds.width
        let height = previewBounds.width * CGFloat(aspectRatio)
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: width,
            height: height)
        detectionLayer.position = CGPoint(
            x: previewBounds.midX,
            y: previewBounds.midY)

        // detectionLayer に緑色の外枠を設定
        let borderWidth = 3.0
        let boxColor = UIColor.green.cgColor
        detectionLayer.borderWidth = borderWidth
        detectionLayer.borderColor = boxColor

        DispatchQueue.main.async { [weak self] in
            if let layer = self?.previewLayer {
                layer.addSublayer(self!.detectionLayer)
            }
        }
    }

    func drawTime(preprocessTime: Float, inferTime: Float, postprocessTime: Float) {
        let text = String(format: "Model: %@, \nPreprocess: %.2fms, \nInfer: %.2fms, \nPostprocess: %.2fms",
                          modelName,
                          preprocessTime, inferTime, postprocessTime)
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 15
        textLayer.frame = CGRect(
            x: 0, y: -20 * 4,
            width: detectionLayer.frame.width,
            height: 20 * 4)
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = UIColor.green.cgColor
        detectionLayer.addSublayer(textLayer)
    }

    func drawDetection(
        bbox: CGRect,
        text: String,
        boxColor: CGColor = UIColor.green.withAlphaComponent(0.5).cgColor,
        textColor: CGColor = UIColor.black.cgColor)
    {
        let boxLayer = CALayer()

        // バウンディングボックスの座標を計算
        let width = detectionLayer.frame.width
        let height = detectionLayer.frame.width
        let bounds = CGRect(
            x: bbox.minX * width,
            y: bbox.minY * height,
            width: (bbox.maxX - bbox.minX) * width + 10,
            height: (bbox.maxY - bbox.minY) * height + 10)
        boxLayer.frame = bounds

        // バウンディングボックスに緑色の外枠を設定
        let borderWidth = 3.0
        boxLayer.borderWidth = borderWidth
        boxLayer.borderColor = boxColor

        // 認識結果のテキストを設定
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 15
        textLayer.frame = CGRect(
            x: 0, y: -20 * 2,
            width: boxLayer.frame.width,
            height: 20 * 2)
        textLayer.backgroundColor = boxColor
        textLayer.foregroundColor = textColor

        boxLayer.addSublayer(textLayer)
        detectionLayer.addSublayer(boxLayer)
    }

    func drawDetections(preds: [Float],
                        preprocessTime: Float = 0.0,
                        inferenceTime: Float = 0.0,
                        postprocessTime: Float = 0.0)
    {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        detectionLayer.sublayers = nil
        drawTime(preprocessTime: preprocessTime,
                 inferTime: inferenceTime,
                 postprocessTime: postprocessTime)
        for i in 0 ..< preds.count / 7 {
            let offset = i * 7
            let clsIdx = preds[offset + 0]
            let score = preds[offset + 1]
            let trackId = preds[offset + 2]
            let x = preds[offset + 3] / Float(detector.InputSizes.3)
            let y = preds[offset + 4] / Float(detector.InputSizes.2)
            let w = preds[offset + 5] / Float(detector.InputSizes.3)
            let h = preds[offset + 6] / Float(detector.InputSizes.2)

            if score < 0.55 {
                continue
            }
            let cls = detector.getClass(clsIdx: clsIdx)
            let bbox = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
            let text = tracking ? String(format: "%d: %@ %.2f\n", Int(trackId), cls, score) : String(format: "%@ %.2f\n", cls, score)
            drawDetection(bbox: bbox, text: text)
        }
        CATransaction.commit()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let modelInputRange = detectionLayer.frame.applying(
            previewLayer.bounds.size.transformKeepAspect(toFitIn: CGSize(width: 1080, height: 1980)))
        let trackingCls = trackingObjs[trackingObj] != nil ? trackingObjs[trackingObj]! : 0
        let output = detector.detect(
            pixelBuffer: pixelBuffer,
            modelInputRange: modelInputRange,
            tracking: tracking,
            trackingCls: trackingCls)
        guard let output = output else {
            os_log("Failed to detect objects.")
            return
        }
        let (preds, preprocessTime, inferenceTime, postprocessTime) = output

        Task { @MainActor in
            drawDetections(preds: preds, preprocessTime: preprocessTime, inferenceTime: inferenceTime, postprocessTime: postprocessTime)
        }
    }
}

struct HostedYoloxViewController: UIViewControllerRepresentable {
    @Binding var aspectRatio: Float
    @Binding var modelName: String
    @Binding var modelPath: String
    @Binding var inputSizes: [Int]
    @Binding var tracking: Bool
    @Binding var trackingObj: String

    func makeUIViewController(context: Context) -> YoloxViewController {
        return YoloxViewController(
            aspectRatio: $aspectRatio,
            modelName: $modelName,
            modelPath: $modelPath,
            inputSizes: $inputSizes,
            tracking: $tracking,
            trackingObj: $trackingObj)
    }

    func updateUIViewController(_ uiViewController: YoloxViewController, context: Context) {
        guard uiViewController.detectionLayer != nil else {
            return
        }
        uiViewController.detectionLayer.frame = CGRect(
            x: uiViewController.detectionLayer.frame.minX,
            y: uiViewController.detectionLayer.frame.minY,
            width: uiViewController.detectionLayer.frame.width,
            height: uiViewController.detectionLayer.frame.width * CGFloat(aspectRatio))
        DispatchQueue.main.async {
            let modelPath = Bundle.main.path(forResource: "Engine_Engine.bundle/" + modelPath, ofType: "pte")!
            uiViewController.detector = Yolox(modelPath: modelPath, inputSizes: inputSizes)
            uiViewController.detector.loadModel()
            uiViewController.tracking = tracking
            uiViewController.trackingObj = trackingObj
        }
    }
}
