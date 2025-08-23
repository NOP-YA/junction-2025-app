//
//  RadarComponent.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

// MARK: - Radar Location View
struct RadarLocationView: View {
    @Binding var animateRadar: Bool
    let riskLevel: RiskLevel
    let userHeading: Double // 사용자가 바라보는 방향 (도)
    
    var body: some View {
        ZStack {
            // Outermost circle (extends beyond screen)
            Circle()
                .stroke(Color.radarGray, lineWidth: 1)
                .frame(width: 750, height: 750)
            
            // Large circle
            Circle()
                .stroke(Color.radarGray, lineWidth: 1)
                .frame(width: 600, height: 600)
            
            // Medium circle
            Circle()
                .stroke(Color.radarGray, lineWidth: 1)
                .frame(width: 450, height: 450)
            
            // Small circle
            Circle()
                .stroke(Color.radarGray, lineWidth: 1)
                .frame(width: 300, height: 300)
            
            // Innermost circle
            Circle()
                .stroke(Color.radarGray, lineWidth: 1)
                .frame(width: 150, height: 150)
            
            // Danger area based on risk level (서쪽)
            DangerAreaView(animateRadar: animateRadar, riskLevel: riskLevel)
                .offset(dangerAreaOffset)
                .animation(.easeInOut(duration: 0.3), value: userHeading) // 헤딩 변화시 애니메이션
            
            // Home icon (남쪽)
            HouseIconView()
                .offset(houseIconOffset)
                .animation(.easeInOut(duration: 0.3), value: userHeading) // 헤딩 변화시 애니메이션
            
            // Center person icon
            PersonIconView()
        }
        .frame(width: 500, height: 500)
        .clipShape(Circle()) // Clip to maintain circular boundary
    }
    
    // MARK: - Computed Properties
    
    /// 위험 지역의 오프셋 (사용자 위치 기준 서쪽)
    private var dangerAreaOffset: CGSize {
        let westPosition = DirectionCalculator.westPosition(userHeading: userHeading)
        return CGSize(width: westPosition.x, height: westPosition.y)
    }
    
    /// 집 아이콘의 오프셋 (사용자 위치 기준 남쪽)
    private var houseIconOffset: CGSize {
        let southPosition = DirectionCalculator.southPosition(userHeading: userHeading)
        return CGSize(width: southPosition.x, height: southPosition.y)
    }
}

// MARK: - Preview
#Preview {
    @State var animate = true
    return RadarLocationView(
        animateRadar: $animate, 
        riskLevel: .immediateEvacuation,
        userHeading: 0.0 // 북쪽을 바라봄
    )
    .background(Color.black)
}
