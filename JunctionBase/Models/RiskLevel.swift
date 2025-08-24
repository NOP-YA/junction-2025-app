//
//  RiskLevel.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import Foundation
import SwiftUI

/// 사용자 위치 기반 위험도 레벨
public enum RiskLevel: String, CaseIterable {
    case immediateEvacuation = "Evacuate Now"
    case evacuationPreparation = "Get Ready to Evacuate"
    case situationMonitoring = "Stay Alert"
    
    /// 위험도 점수에 따른 레벨 결정 (KFSCategory 기준)
    public static func from(riskScore: Double) -> RiskLevel {
        switch riskScore {
        case 86...100:
            return .immediateEvacuation  // 매우높음 → 즉시 대피
        case 51..<86:
            return .evacuationPreparation  // 다소높음, 높음 → 대피 준비
        case 0..<51:
            return .situationMonitoring  // 낮음 → 상황 주시
        default:
            return .situationMonitoring
        }
    }
    
    /// 각 레벨의 주요 색상
    public var primaryColor: Color {
        switch self {
        case .immediateEvacuation:
            return Color(hex: "790000") // 진한 빨강
        case .evacuationPreparation:
            return Color(hex: "793700") // 어두운 주황
        case .situationMonitoring:
            return Color(hex: "795D00") // 어두운 노랑
        }
    }
    
    /// 각 레벨의 제목 텍스트
    public var title: String {
        return self.rawValue
    }
    
    /// 각 레벨의 설명 메시지
    public var description: String {
        switch self {
        case .immediateEvacuation:
            return "Evacuate to the\n Shelter Immediately!"
        case .evacuationPreparation:
            return "Be Prepared\nfor any Emergency!"
        case .situationMonitoring:
            return "Check nearby\n wildfire information."
        }
    }
    
    /// 각 레벨의 서브 메시지
    public var subDescription: String {
        switch self {
        case .immediateEvacuation:
            return "Your location is in the fire path"
        case .evacuationPreparation:
            return "The wildfire could reach your area"
        case .situationMonitoring:
            return "Safe for now, but smoke may enter"
        }
    }
    
    /// 각 레벨의 아이콘
    public var iconName: String {
        switch self {
        case .immediateEvacuation:
            return "exclamationmark.triangle.fill"
        case .evacuationPreparation:
            return "house.fill"
        case .situationMonitoring:
            return "eye.fill"
        }
    }
}
