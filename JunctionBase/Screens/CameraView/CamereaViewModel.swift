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
        
        // 알림 설정을 즉시 요청
        Task {
            await ensureNotificationSetup()
        }
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
    
    /// Ensure local notification setup (categories + permission). Safe to call multiple times.
    func ensureNotificationSetup() async {
        let center = UNUserNotificationCenter.current()
        
        // 1. 권한 먼저 요청
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if !granted {
                return
            }
            
            // 2. 현재 설정 확인
            let settings = await center.notificationSettings()
            
            // 3. 카테고리 설정
            // Provide foreground action so users can reopen the app from a delivered notification.
            let openAction = UNNotificationAction(identifier: "OPEN_APP",
                                                  title: "열기",
                                                  options: [.foreground])

            let fireCategory = UNNotificationCategory(
                identifier: "FIRE_ALERT",
                actions: [openAction],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )

            let openCameraCategory = UNNotificationCategory(
                identifier: "OPEN_CAMERA",
                actions: [openAction],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )

            center.setNotificationCategories([fireCategory, openCameraCategory])
            
        } catch {
            // 알림 권한 요청 실패 시 조용히 실패 처리
        }
    }


    
    /// Sends a local notification for risk level analysis (immediate, time-sensitive)
    func sendNavigationNotification(for riskLevel: RiskLevel) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Wildfire Risk Alert"
            switch riskLevel {
            case .situationMonitoring:
                content.body = "[Information] Wildfire reported near Seonchak-ro 78, Buk-gu, Pohang. Stay alert and report safely if possible."
                content.badge = 1
            case .evacuationPreparation:
                content.body = "[Alert] Wildfire spreading near Seonchak-ro 78, Buk-gu, Pohang. Prepare to evacuate and follow official guidance."
                content.badge = 2
            case .immediateEvacuation:
                content.body = "[Emergency] Wildfire near Seonchak-ro 78, Buk-gu, Pohang. Evacuate immediately to the nearest shelter."
                content.badge = 3
            }
            content.categoryIdentifier = "FIRE_ALERT"
            content.sound = .default
            content.threadIdentifier = "fire.alert"
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
                if #available(iOS 16.0, *) {
                    content.relevanceScore = 1.0
                }
            }

            // 즉시 발송: trigger = nil
            let request = UNNotificationRequest(
                identifier: "risk_\(riskLevel.rawValue)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )

            do {
                try await center.add(request)
            } catch {
                // 알림 전송 실패 시 조용히 실패 처리
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

// RiskLevel enum은 이미 프로젝트에 정의되어 있음

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
