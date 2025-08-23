//
//  DeviceHeadingManager.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import Foundation
import CoreMotion
import Combine

class DeviceHeadingManager: NSObject, ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var deviceHeading: Double = 0.0 // 기기가 바라보는 방향 (도)
    @Published var isDeviceMotionAvailable: Bool = false
    @Published var isUpdating: Bool = false
    
    override init() {
        super.init()
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable
        
        if isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1 // 0.1초마다 업데이트
        }
    }
    
    func startDeviceMotionUpdates() {
        guard isDeviceMotionAvailable else { return }
        guard !isUpdating else { return }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error { return }
            guard let motion = motion else { return }
            
            // 기기 방향 계산 (Z축 회전)
            let heading = self.calculateHeading(from: motion)
            
            DispatchQueue.main.async {
                self.deviceHeading = heading
                self.isUpdating = true
            }
        }
    }
    
    func stopDeviceMotionUpdates() {
        guard isUpdating else { return }
        
        motionManager.stopDeviceMotionUpdates()
        
        DispatchQueue.main.async {
            self.isUpdating = false
        }
    }
    
    private func calculateHeading(from motion: CMDeviceMotion) -> Double {
        // 기기의 Z축 회전을 기반으로 방향 계산
        let attitude = motion.attitude
        
        // Roll, Pitch, Yaw에서 Yaw(편향)를 사용
        let yaw = attitude.yaw * 180.0 / .pi // 라디안을 도로 변환
        
        // 0-360도 범위로 정규화
        var heading = yaw
        if heading < 0 {
            heading += 360.0
        }
        
        return heading
    }
    

    
    deinit {
        stopDeviceMotionUpdates()
    }
}
