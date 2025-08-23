//
//  CameraViewModel.swift
//  JunctionBase
//
//  Created by Henry on 8/24/25.
//

import Foundation
import AVFoundation
import SwiftUI
import CoreMotion
import UserNotifications

/// ViewModel that manages a bare-metal camera session (no default system UI)
@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    // Public observable states
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var lastPhotoData: Data?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isDirectionCorrect: Bool = false
    @Published private(set) var cameraFrozen: Bool = false

    // Capture session & outputs
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    
    // Motion tracking
    private let motionManager = CMMotionManager()
    private var currentYaw: Double = 0
    private var baseYaw: Double = 0
    private var hasMovedRight = false
    
    // MARK: - Local Notification Helpers
    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        // Define a basic category so tapping can relaunch the app (future: handle action to reopen camera)
        let category = UNNotificationCategory(
            identifier: "OPEN_CAMERA",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Task { @MainActor in self.errorMessage = error.localizedDescription }
                return
            }
            // 권한 거부 시에도 앱 크래시는 방지
        }
    }

    private func sendCaptureDoneNotification() {
        let content = UNMutableNotificationContent()
        content.title = "촬영 완료"
        content.body = "화재 상황 사진이 저장되었습니다. 필요시 추가 촬영을 진행하세요."
        content.sound = .default
        content.categoryIdentifier = "OPEN_CAMERA"

        // 즉시 발송 (약간의 지연을 줘서 UI 전환과 겹치지 않게)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: "capture_done_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Permission & configuration
    func requestAccessAndConfigure() {
        Task {
            // 알림 권한 및 카테고리 등록
            requestNotificationAuthorization()
            
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                isAuthorized = true
                await configureSession()
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                isAuthorized = granted
                if granted {
                    await configureSession()
                }
            default:
                isAuthorized = false
                errorMessage = "Camera permission denied"
            }
        }
        
        // 모션 트래킹 시작
        startMotionTracking()
    }

    private func configureSession() async {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self, photoOutput, session] in
                defer { continuation.resume() }
                
                guard let self else { return }

                session.beginConfiguration()
                session.sessionPreset = .high

                // Input: back wide camera
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                         for: .video,
                                                         position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      session.canAddInput(input) else {
                    Task { @MainActor in
                        self.errorMessage = "Cannot create camera input"
                    }
                    session.commitConfiguration()
                    return
                }
                session.addInput(input)

                // Output: photo only (no system UI)
                guard session.canAddOutput(photoOutput) else {
                    Task { @MainActor in
                        self.errorMessage = "Cannot add photo output"
                    }
                    session.commitConfiguration()
                    return
                }
                session.addOutput(photoOutput)
                
                // iOS 16+ API 사용 - 지원되는 최대 해상도 설정
                if #available(iOS 16.0, *) {
                    if let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions.max(by: {
                        $0.width * $0.height < $1.width * $1.height
                    }) {
                        photoOutput.maxPhotoDimensions = maxDimensions
                    }
                } else {
                    photoOutput.isHighResolutionCaptureEnabled = true
                }

                session.commitConfiguration()
                
                // auto-start after configuration
                Task { await self.start() }
            }
        }
    }

    // MARK: - Control
    func start() async {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self, session] in
                defer { continuation.resume() }
                
                guard let self, !session.isRunning else { return }
                session.startRunning()
                
                Task { @MainActor in
                    self.isRunning = true
                }
            }
        }
    }

    func stop() async {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self, session] in
                defer { continuation.resume() }
                
                guard let self, session.isRunning else { return }
                session.stopRunning()
                
                Task { @MainActor in
                    self.isRunning = false
                }
            }
        }
    }

    // MARK: - Capture
    func capturePhoto() {
        // 카메라 화면을 고정 상태로 변경
        cameraFrozen = true
        
        Task {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                sessionQueue.async { [weak self, photoOutput] in
                    defer { continuation.resume() }
                    
                    guard let self else { return }
                    
                    let settings = AVCapturePhotoSettings()
                    
                    // iOS 16+ API 사용 - 지원되는 최대 해상도 설정
                    if #available(iOS 16.0, *) {
                        // photoOutput의 maxPhotoDimensions를 사용 (이미 설정됨)
                    } else {
                        settings.isHighResolutionPhotoEnabled = true
                    }
                    
                    photoOutput.capturePhoto(with: settings, delegate: self)
                }
            }
        }
    }
    
    // MARK: - Motion Tracking
    private func startMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            self.currentYaw = motion.attitude.yaw * 180 / .pi
            
            // 첫 번째 값을 기준점으로 설정
            if self.baseYaw == 0 {
                self.baseYaw = self.currentYaw
                return
            }
            
            self.updateDirectionStatus()
        }
    }
    
    private func stopMotionTracking() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func updateDirectionStatus() {
        // yaw 차이 계산 (360도 경계 처리)
        var yawDiff = currentYaw - baseYaw
        
        // 180도를 넘으면 반대 방향으로 계산
        if yawDiff > 180 {
            yawDiff -= 360
        } else if yawDiff < -180 {
            yawDiff += 360
        }
        
        // 오른쪽으로 20도 이상 돌렸으면 성공으로 간주하고 계속 유지
        if yawDiff > 20 {
            hasMovedRight = true
        }
        
        // 한 번 오른쪽으로 돌렸다면 계속 OK 상태 유지 (너무 왼쪽으로 가지 않는 한)
        if hasMovedRight {
            isDirectionCorrect = yawDiff > -10 // 기준점보다 왼쪽으로 10도까지는 OK
        } else {
            isDirectionCorrect = false
        }
    }
    
    // Computed property to expose session for SwiftUI
    var captureSession: AVCaptureSession { session }
}

// MARK: - Photo delegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        Task { @MainActor in
            if let error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            self.lastPhotoData = photo.fileDataRepresentation()
            self.errorMessage = nil
            
            // 촬영 완료 알림 발송
            self.sendCaptureDoneNotification()
        }
    }
}

// MARK: - SwiftUI Preview Layer wrapper
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // No updates needed for this implementation
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
