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
                .font(.pretendardBold24)
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                
            // Location warning message
            Text(riskLevel.subDescription)
                .font(.pretendardMedium20)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 40)
    }

}
