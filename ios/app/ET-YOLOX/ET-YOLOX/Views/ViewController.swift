//
//  ViewController.swift
//  ET-YOLOX
//
//  Created by kikemori on 2024/12/22.
//

import AVFoundation
import SwiftUI
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // For AVCaputre session
    private var permissionGranted = false // Flag for permission
    private var videoDevice: AVCaptureDevice?
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private lazy var videoOutput = AVCaptureVideoDataOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var previewBounds: CGRect! = nil // for view dimensions

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermission()
        sessionQueue.async { [unowned self] in
            guard self.permissionGranted else { return }
            self.setupCaptureSession()
            self.setupLayers()
            self.captureSession.startRunning()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        stopCaptureSession()
    }

    func startCaputreSession() {
        if !captureSession.isRunning {
            sessionQueue.async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    func stopCaptureSession() {
        if captureSession.isRunning {
            sessionQueue.async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        // Permission has been granted before
        case .authorized:
            permissionGranted = true
        // Permission has not been requested yet
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {
            [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        })
    }

    func setupLayers() {}

    func getCameraDevice() -> AVCaptureDevice.DeviceType? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
            ],
            mediaType: .video,
            position: .back)
        let availableDevices = discoverySession.devices

        if availableDevices.contains(
            where: { $0.deviceType == .builtInTripleCamera })
        {
            return .builtInTripleCamera
        }
        if availableDevices.contains(
            where: { $0.deviceType == .builtInDualWideCamera })
        {
            return .builtInDualWideCamera
        }
        if availableDevices.contains(
            where: { $0.deviceType == .builtInWideAngleCamera })
        {
            return .builtInWideAngleCamera
        }
        return nil
    }

    func setupCaptureSession() {
        guard let cameraDeviceType = getCameraDevice() else {
            fatalError("Failed to get a correct camera device")
        }
        guard let videoDevice
            = AVCaptureDevice.default(cameraDeviceType, for: .video, position: .back)
        else {
            fatalError("Failed to get AVCaptureDevice")
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Failed to get AVCaptureInputdevice")
        }
        self.videoDevice = videoDevice

        guard captureSession.canAddInput(videoDeviceInput) else {
            fatalError("Cannot add videodevice input")
        }
        captureSession.addInput(videoDeviceInput)

        guard captureSession.canAddOutput(videoOutput) else {
            fatalError("Cannot add videodevice output")
        }
        captureSession.addOutput(videoOutput)

        guard captureSession.canSetSessionPreset(.high) else {
            fatalError("Failed to set session preset")
        }
        captureSession.sessionPreset = .high
        let previewFrame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height)
        previewBounds = CGRect(
            x: 0,
            y: 0,
            width: previewFrame.width,
            height: previewFrame.height)
        let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        // MARK: - カメラ出力のピクセルフォーマットで `kCMPixelFormat_32BGRA` を指定

        videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCMPixelFormat_32BGRA]
        videoOutput.connection(with: .video)?.videoRotationAngle = 90.0

        DispatchQueue.main.async { [weak self] in
            self!.previewLayer = AVCaptureVideoPreviewLayer(session: self!.captureSession)
            self!.previewLayer.frame = previewFrame
            self!.previewLayer.bounds = self!.previewBounds
            self!.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
