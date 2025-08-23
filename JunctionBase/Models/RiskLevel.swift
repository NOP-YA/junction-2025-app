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
    case immediateEvacuation = "즉시 대피"
    case evacuationPreparation = "대피 준비"  
    case situationMonitoring = "상황 주시"
    
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
            return .red
        case .evacuationPreparation:
            return .orange
        case .situationMonitoring:
            return .yellow
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
            return "지금 즉시 대피소로 이동하세요!"
        case .evacuationPreparation:
            return "만일의 상황에 대비하세요!"
        case .situationMonitoring:
            return "인근 산불 정보를 확인하세요"
        }
    }
    
    /// 각 레벨의 서브 메시지
    public var subDescription: String {
        switch self {
        case .immediateEvacuation:
            return "계신 곳이 화재 경로에 포함되었습니다."
        case .evacuationPreparation:
            return "산불이 현재 위치로 확산될 수 있습니다."
        case .situationMonitoring:
            return "직접 위험은 없으나 연기 유입에 주의하세요"
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
