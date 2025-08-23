//
//  EmergencyTextComponent.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

// MARK: - Emergency Text View
struct EmergencyTextView: View {
    let riskLevel: RiskLevel
    
    var body: some View {
        VStack(spacing: 12) {
            // Main emergency message
            Text(riskLevel.description)
                .font(.pretendardSemiBold24)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                
            // Location warning message
            Text(riskLevel.subDescription)
                .font(.pretendardMedium20)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                
            // Action guide icon and text
            VStack(spacing: 8) {
                Image(systemName: actionIconName)
                    .font(.system(size: 44))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(actionText)
                    .font(.pretendardBold20)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var actionIconName: String {
        switch riskLevel {
        case .immediateEvacuation:
            return "book.closed"
        case .evacuationPreparation:
            return "house.fill"
        case .situationMonitoring:
            return "eye.fill"
        }
    }
    
    private var actionText: String {
        switch riskLevel {
        case .immediateEvacuation:
            return "행동가이드"
        case .evacuationPreparation:
            return "대피준비"
        case .situationMonitoring:
            return "상황파악"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 50) {
        EmergencyTextView(riskLevel: .immediateEvacuation)
        EmergencyTextView(riskLevel: .evacuationPreparation)
        EmergencyTextView(riskLevel: .situationMonitoring)
    }
    .background(Color.black)
}
