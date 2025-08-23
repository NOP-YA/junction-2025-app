//
//  DirectionCalculator.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import Foundation
import CoreGraphics

struct DirectionCalculator {
    
    /// 사용자의 헤딩을 기준으로 특정 방향의 상대적 위치를 계산합니다.
    /// - Parameters:
    ///   - userHeading: 사용자가 바라보는 방향 (0° = 북쪽, 90° = 동쪽, 180° = 남쪽, 270° = 서쪽)
    ///   - targetDirection: 목표 방향 (0° = 북쪽, 90° = 동쪽, 180° = 남쪽, 270° = 서쪽)
    ///   - distance: 중심에서의 거리 (픽셀)
    /// - Returns: 중심을 기준으로 한 상대적 위치 (x, y)
    static func relativePosition(
        userHeading: Double,
        targetDirection: Double,
        distance: Double = 120.0
    ) -> CGPoint {
        // 사용자 헤딩을 기준으로 한 상대적 각도 계산
        let relativeAngle = targetDirection - userHeading
        
        // 각도를 라디안으로 변환
        let angleInRadians = relativeAngle * .pi / 180.0
        
        // 상대적 위치 계산 (화면 좌표계: y축이 아래쪽으로 증가)
        let x = distance * sin(angleInRadians)
        let y = -distance * cos(angleInRadians) // y축 반전 (화면 좌표계)
        
        return CGPoint(x: x, y: y)
    }
    
    /// 서쪽 방향의 상대적 위치를 계산합니다.
    static func westPosition(userHeading: Double, distance: Double = 80.0) -> CGPoint {
        return relativePosition(userHeading: userHeading, targetDirection: 270.0, distance: distance)
    }
    
    /// 남쪽 방향의 상대적 위치를 계산합니다.
    static func southPosition(userHeading: Double, distance: Double = 200.0) -> CGPoint {
        return relativePosition(userHeading: userHeading, targetDirection: 180.0, distance: distance)
    }
    
    /// 북쪽 방향의 상대적 위치를 계산합니다.
    static func northPosition(userHeading: Double, distance: Double = 120.0) -> CGPoint {
        return relativePosition(userHeading: userHeading, targetDirection: 0.0, distance: distance)
    }
    
    /// 동쪽 방향의 상대적 위치를 계산합니다.
    static func eastPosition(userHeading: Double, distance: Double = 120.0) -> CGPoint {
        return relativePosition(userHeading: userHeading, targetDirection: 90.0, distance: distance)
    }
}

// MARK: - Preview Helper
#if DEBUG
extension DirectionCalculator {
    static func previewPositions() -> [(direction: String, position: CGPoint)] {
        let userHeading = 0.0 // 북쪽을 바라봄
        
        return [
            ("West", westPosition(userHeading: userHeading)),
            ("South", southPosition(userHeading: userHeading)),
            ("North", northPosition(userHeading: userHeading)),
            ("East", eastPosition(userHeading: userHeading))
        ]
    }
}
#endif
