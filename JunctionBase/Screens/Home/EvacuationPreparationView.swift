//
//  EvacuationPreparationView.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

struct EvacuationPreparationView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var animateRadar: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Dark gray background to match design
            Color(red: 0.15, green: 0.15, blue: 0.17)
                .ignoresSafeArea()
        
            VStack(alignment: .center, spacing: 30) {
                // Title
                Text(RiskLevel.evacuationPreparation.title)
                    .font(.pretendardMedium28)
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                // Radar view
                RadarLocationView(
                    animateRadar: $animateRadar, 
                    riskLevel: .evacuationPreparation,
                    userHeading: homeViewModel.userHeading
                )
                .frame(width: 400, height: 400)
                
                Spacer()
                
                // Bottom emergency text
                EmergencyTextView(riskLevel: .evacuationPreparation)
                    .padding(.bottom, 80)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startRadarAnimation()
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    private func startRadarAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            animateRadar = true
        }
    }
}

// MARK: - Preview
#Preview {
    EvacuationPreparationView()
}
