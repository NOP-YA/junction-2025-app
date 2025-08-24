//
//  EvacuationLocationView.swift
//  JunctionBase
//
//  Created by bear on 8/23/25.
//

import SwiftUI

struct EvacuationLocationView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @State private var animateRadar: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background image
            Image("EmptyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        
            VStack(alignment: .center, spacing: 20) {
                // Title with circular background
                Text(RiskLevel.immediateEvacuation.title)
                    .font(.pretendardBold20)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(RiskLevel.immediateEvacuation.primaryColor)
                    )
                    .padding(.top, 100)
                
                Spacer()
                
                // Radar view
                RadarLocationView(
                    animateRadar: $animateRadar, 
                    riskLevel: .immediateEvacuation,
                    userHeading: homeViewModel.userHeading
                )
                .frame(width: 400, height: 400)
                
                Spacer()
                
                // Bottom emergency text
                EmergencyTextView(riskLevel: .immediateEvacuation)
                    .padding(.bottom, 160)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // 위치 추적 시작 (권한은 이미 ContentView에서 요청됨)
            
            // 약간의 딜레이 후 추적 시작 시도
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                homeViewModel.locationManager.startTracking()
            }
            
            // 레이아웃이 안정화된 후 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startRadarAnimation()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    private func startRadarAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
                .delay(0.1) // 약간의 지연으로 안정화
        ) {
            animateRadar = true
        }
    }
}



#Preview {
    EvacuationLocationView(homeViewModel: HomeViewModel())
}
