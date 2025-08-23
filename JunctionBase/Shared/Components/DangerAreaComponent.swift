//
//  DangerAreaComponent.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import SwiftUI
import Foundation

// MARK: - Fire Sector Shape (불꽃 모양)
struct DangerSector: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseOuterRadius = min(rect.width, rect.height) / 2
        let innerRadius: CGFloat = 75 // 내부 반지름
        
        // 불꽃 모양을 위한 불규칙한 점들 생성
        let angleStep = (endAngle.radians - startAngle.radians) / 20 // 20개 점으로 분할
        var outerPoints: [CGPoint] = []
        
        // 바깥쪽 불규칙한 가장자리 생성
        for i in 0...20 {
            let currentAngle = startAngle.radians + (Double(i) * angleStep)
            
            // 불꽃 효과: 반지름을 불규칙하게 변화
            let radiusVariation = sin(currentAngle * 3) * 20 + cos(currentAngle * 5) * 15
            let irregularRadius = baseOuterRadius + radiusVariation
            
            let point = CGPoint(
                x: center.x + Foundation.cos(currentAngle) * irregularRadius,
                y: center.y + Foundation.sin(currentAngle) * irregularRadius
            )
            outerPoints.append(point)
        }
        
        // 바깥쪽 불규칙한 곡선 그리기
        if let firstPoint = outerPoints.first {
            path.move(to: firstPoint)
            
            for i in 1..<outerPoints.count {
                let currentPoint = outerPoints[i]
                
                if i == 1 {
                    path.addLine(to: currentPoint)
                } else {
                    // 부드러운 곡선으로 연결 (불꽃 느낌)
                    let previousPoint = outerPoints[i-1]
                    let controlPoint = CGPoint(
                        x: (previousPoint.x + currentPoint.x) / 2,
                        y: (previousPoint.y + currentPoint.y) / 2 + sin(Double(i)) * 5
                    )
                    path.addQuadCurve(to: currentPoint, control: controlPoint)
                }
            }
        }
        
        // 끝점에서 안쪽으로
        let innerEndPoint = CGPoint(
            x: center.x + Foundation.cos(endAngle.radians) * innerRadius,
            y: center.y + Foundation.sin(endAngle.radians) * innerRadius
        )
        path.addLine(to: innerEndPoint)
        
        // 안쪽 호 그리기
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Danger Area View (Sector-based)
struct DangerAreaView: View {
    let animateRadar: Bool
    let riskLevel: RiskLevel
    let directionAngle: Double // 위험 방향 각도 (도)
    
    var body: some View {
        ZStack {
            // Main fire sector - 더 넓은 화염 범위
            DangerSector(
                startAngle: .degrees(directionAngle - 60), // ±60도 범위로 확대
                endAngle: .degrees(directionAngle + 60)
            )
            .fill(fireGradientForRiskLevel)
            .opacity(animateRadar ? 0.9 : 0.7)
            .scaleEffect(animateRadar ? 1.02 : 0.98) // 더 미묘한 화염 효과
            .animation(
                Animation.easeInOut(duration: 4.0) // 더 천천히 숨쉬는 느낌
                    .repeatForever(autoreverses: true),
                value: animateRadar
            )
            
            // 추가 화염 레이어 (깊이감)
            DangerSector(
                startAngle: .degrees(directionAngle - 45),
                endAngle: .degrees(directionAngle + 45)
            )
            .fill(innerFireGradient)
            .opacity(animateRadar ? 0.5 : 0.3)
            .scaleEffect(animateRadar ? 0.95 : 1.05) // 더 미묘한 반대 방향 애니메이션
            .animation(
                Animation.easeInOut(duration: 3.5) // 메인보다 조금 빠르게
                    .repeatForever(autoreverses: true),
                value: animateRadar
            )
        }
        .frame(width: 500, height: 500) // RadarComponent와 동일한 크기
    }
    
    // 메인 화염 그라데이션 (더 강렬함)
    private var fireGradientForRiskLevel: RadialGradient {
        switch riskLevel {
        case .immediateEvacuation:
            return RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.7, blue: 0.3, opacity: 0.8), // 바깥: 연한 오렌지 (자연스러운 불빛)
                    Color(red: 1.0, green: 0.5, blue: 0.1, opacity: 0.7), // 연한 주황
                    Color(red: 1.0, green: 0.3, blue: 0.0, opacity: 0.6), // 주황
                    Color(red: 0.9, green: 0.1, blue: 0.0, opacity: 0.5), // 연한 빨강
                    Color(red: 0.7, green: 0.0, blue: 0.0, opacity: 0.4), // 어두운 빨강
                    Color(red: 0.4, green: 0.0, blue: 0.0, opacity: 0.3) // 안쪽: 매우 어두운 빨강
                ],
                center: .center,
                startRadius: 270, // 바깥에서 시작
                endRadius: 60     // 안쪽으로 집중
            )
        case .evacuationPreparation:
            return RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.28, blue: 0.0, opacity: 0.8), // 바깥: FF4800 오렌지 (이미지와 동일)
                    Color(red: 0.95, green: 0.25, blue: 0.0, opacity: 0.7), // 중간 오렌지
                    Color(red: 0.9, green: 0.22, blue: 0.0, opacity: 0.6), // 어두운 오렌지
                    Color(red: 0.85, green: 0.19, blue: 0.0, opacity: 0.5), // 더 어두운 오렌지
                    Color(red: 0.8, green: 0.16, blue: 0.0, opacity: 0.4), // 어두운 적갈색
                    Color(red: 0.6, green: 0.17, blue: 0.0, opacity: 0.3) // 안쪽: 992B00 어두운 적갈색 (이미지와 동일)
                ],
                center: .center,
                startRadius: 270, // 바깥에서 시작
                endRadius: 60     // 안쪽으로 집중
            )
        case .situationMonitoring:
            return RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.6, opacity: 0.6), // 바깥: 매우 연한 노랑-주황 (부드러운 경고)
                    Color(red: 1.0, green: 0.8, blue: 0.5, opacity: 0.5), // 연한 노랑
                    Color(red: 1.0, green: 0.7, blue: 0.4, opacity: 0.4), // 연한 주황
                    Color(red: 0.9, green: 0.6, blue: 0.3, opacity: 0.3), // 어두운 노랑-주황
                    Color(red: 0.8, green: 0.5, blue: 0.2, opacity: 0.2), // 더 어두운 노랑
                    Color(red: 0.7, green: 0.4, blue: 0.1, opacity: 0.1) // 안쪽: 매우 어두운 노랑 (매우 연함)
                ],
                center: .center,
                startRadius: 270, // 바깥에서 시작
                endRadius: 60     // 안쪽으로 집중
            )
        }
    }
    
    // 내부 화염 그라데이션 (중심부 뜨거운 불꽃 효과)
    private var innerFireGradient: RadialGradient {
        switch riskLevel {
        case .immediateEvacuation:
            return RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.6, blue: 0.1, opacity: 0.4), // 바깥: 연한 주황 (불꽃색)
                    Color(red: 1.0, green: 0.8, blue: 0.2, opacity: 0.5), // 밝은 노랑
                    Color(red: 1.0, green: 0.9, blue: 0.4, opacity: 0.6), // 밝은 노랑-흰색
                    Color.white.opacity(0.7) // 중심: 흰색 (뜨거운 불꽃)
                ],
                center: .center,
                startRadius: 120, // 바깥에서 시작
                endRadius: 30     // 중심으로 집중
            )
        case .evacuationPreparation:
            return RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.28, blue: 0.0, opacity: 0.4), // 바깥: FF4800 오렌지 (이미지와 동일)
                    Color(red: 1.0, green: 0.4, blue: 0.1, opacity: 0.5), // 밝은 오렌지
                    Color(red: 0.9, green: 0.3, blue: 0.0, opacity: 0.6), // 중간 오렌지
                    Color(red: 0.6, green: 0.17, blue: 0.0, opacity: 0.7) // 안쪽: 992B00 어두운 적갈색 (이미지와 동일)
                ],
                center: .center,
                startRadius: 120, // 바깥에서 시작
                endRadius: 30     // 중심으로 집중
            )
        case .situationMonitoring:
            return RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.6, opacity: 0.3), // 바깥: 매우 연한 노랑-주황 (부드러운 경고)
                    Color(red: 1.0, green: 0.8, blue: 0.5, opacity: 0.4), // 연한 노랑
                    Color(red: 1.0, green: 0.7, blue: 0.4, opacity: 0.5), // 연한 주황
                    Color(red: 0.8, green: 0.6, blue: 0.3, opacity: 0.6) // 안쪽: 어두운 노랑 (매우 연함)
                ],
                center: .center,
                startRadius: 120, // 바깥에서 시작
                endRadius: 30     // 중심으로 집중
            )
        }
    }
}



// MARK: - Preview
#Preview {
    @State var animate = true
    return DangerAreaView(
        animateRadar: animate, 
        riskLevel: .immediateEvacuation,
        directionAngle: 45 // 북동쪽 방향으로 테스트
    )
    .background(Color.black)
}
