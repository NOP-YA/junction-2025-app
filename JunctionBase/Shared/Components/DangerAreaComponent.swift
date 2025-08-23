//
//  DangerAreaComponent.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

// MARK: - Danger Area View (Properly Clipped External Circles)
struct DangerAreaView: View {
    let animateRadar: Bool
    let riskLevel: RiskLevel
    
    var body: some View {
        // Single centered danger area that will be offset by RadarComponent
        ZStack {
            // Main danger circle
            ExternalDangerCircle(
                animateRadar: animateRadar,
                isMain: true,
                offsetX: 0, // 중앙 배치 - RadarComponent에서 offset 적용
                offsetY: 0,
                size: 100, // 크기 대폭 축소 (레이더 경계 내 유지)
                riskLevel: riskLevel
            )
            
            // Secondary smaller circle for depth
            ExternalDangerCircle(
                animateRadar: animateRadar,
                isMain: false,
                offsetX: 15,
                offsetY: -10,
                size: 70, // 더 작게
                riskLevel: riskLevel
            )
        }
        .frame(width: 130, height: 130) // 전체 크기 제한 (더 작게)
        .clipped() // 경계를 벗어나지 않도록
    }
}

// MARK: - External Danger Circle
struct ExternalDangerCircle: View {
    let animateRadar: Bool
    let isMain: Bool
    let offsetX: CGFloat
    let offsetY: CGFloat
    let size: CGFloat
    let riskLevel: RiskLevel
    
    var body: some View {
        Circle()
            .fill(gradientForRiskLevel)
            .frame(width: size, height: size)
            .offset(x: offsetX, y: offsetY)
            .scaleEffect(animateRadar ? (isMain ? 1.03 : 0.97) : (isMain ? 0.97 : 1.03))
            .opacity(animateRadar ? (isMain ? 0.9 : 0.7) : (isMain ? 0.8 : 0.6))
            .animation(
                Animation.easeInOut(duration: isMain ? 3.0 : 3.5)
                    .repeatForever(autoreverses: true),
                value: animateRadar
            )
    }
    
    private var gradientForRiskLevel: RadialGradient {
        switch riskLevel {
        case .immediateEvacuation:
            return RadialGradient(
                colors: isMain ? [
                    .red.opacity(0.9),
                    .red.opacity(0.7),
                    .orange.opacity(0.5),
                    .red.opacity(0.3),
                    .clear
                ] : [
                    .orange.opacity(0.7),
                    .red.opacity(0.5),
                    .orange.opacity(0.3),
                    .clear
                ],
                center: .center,
                startRadius: size * 0.1,
                endRadius: size / 2
            )
        case .evacuationPreparation:
            return RadialGradient(
                colors: isMain ? [
                    .orange.opacity(0.9),
                    .orange.opacity(0.7),
                    .yellow.opacity(0.5),
                    .orange.opacity(0.3),
                    .clear
                ] : [
                    .yellow.opacity(0.7),
                    .orange.opacity(0.5),
                    .yellow.opacity(0.3),
                    .clear
                ],
                center: .center,
                startRadius: size * 0.1,
                endRadius: size / 2
            )
        case .situationMonitoring:
            return RadialGradient(
                colors: isMain ? [
                    .yellow.opacity(0.8),
                    .yellow.opacity(0.6),
                    .orange.opacity(0.4),
                    .yellow.opacity(0.2),
                    .clear
                ] : [
                    .orange.opacity(0.6),
                    .yellow.opacity(0.4),
                    .orange.opacity(0.2),
                    .clear
                ],
                center: .center,
                startRadius: size * 0.1,
                endRadius: size / 2
            )
        }
    }
}

// MARK: - Preview
//#Preview {
//    @State var animate = true
//    return DangerAreaView(animateRadar: $animate, riskLevel: .immediateEvacuation)
//        .background(Color.black)
//}
