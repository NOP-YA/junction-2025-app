//
//  EvacuationLocationView.swift
//  UI
//
//  Created by bear on 8/23/25.
//

import SwiftUI

struct EvacuationLocationView: View {
    @StateObject private var vm = HomeViewModel(azureAIService: AzureAIService())
    @Environment(\.dismiss) private var dismiss
    @State private var animateRadar = false
    
    var body: some View {
        ZStack {
            // Dark gray background to match design
            Color(red: 0.15, green: 0.15, blue: 0.17)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status bar space and title
                VStack(spacing: 75) {
                    // Title
                    Text("즉시 대피")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.top,25)
                        
                    
                    // Radar view
                    RadarLocationView(animateRadar: $animateRadar)
                        .frame(width: 300, height: 300)
                }
                
                Spacer()
                
                // Bottom emergency text
                EmergencyTextView()
                    .padding(.bottom, 100)
            }
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

// MARK: - Radar Location View
struct RadarLocationView: View {
    @Binding var animateRadar: Bool
    
    var body: some View {
        ZStack {
            // Gray background fill for radar area
            Circle()
                .fill(Color.gray.opacity(0.05))
                .frame(width: 390, height: 390)
            
            // Base circle (white outline)
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 390, height: 390)
            
            // Inner circles for radar effect - white/light gray
            ForEach(1..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: CGFloat(390 - index * 100), height: CGFloat(390 - index * 100))
            }
            
            // Fire/danger area (red gradient) - properly clipped
            DangerAreaView(animateRadar: animateRadar)
            
            // Center person icon
            PersonIconView()
        }
    }
}

// MARK: - Danger Area View (Properly Clipped External Circles)
struct DangerAreaView: View {
    let animateRadar: Bool
    
    var body: some View {
        // Use proper mask to clip danger circles to radar bounds only
        ZStack {
            // Primary external danger circle from top-right
            ExternalDangerCircle(
                animateRadar: animateRadar,
                isMain: true,
                offsetX: 140,
                offsetY: -90,
                size: 320
            )
            
            // Secondary danger circle from right side
            ExternalDangerCircle(
                animateRadar: animateRadar,
                isMain: false,
                offsetX: 160,
                offsetY: 20,
                size: 240
            )
            
            // Tertiary small danger circle for more realistic effect
            ExternalDangerCircle(
                animateRadar: animateRadar,
                isMain: false,
                offsetX: 100,
                offsetY: -140,
                size: 180
            )
        }
        .mask(
            // Circular mask to ensure danger circles only show within radar bounds
            Circle()
                .frame(width: 390, height: 390)
        )
    }
}

// MARK: - External Danger Circle
struct ExternalDangerCircle: View {
    let animateRadar: Bool
    let isMain: Bool
    let offsetX: CGFloat
    let offsetY: CGFloat
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
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
            )
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
}

// MARK: - Person Icon View
struct PersonIconView: View {
    var body: some View {
        ZStack {
            // White circle background
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
            
            // Person icon
            Image(systemName: "person.fill")
                .font(.system(size: 65))
                .foregroundColor(.black)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Emergency Text View
    struct EmergencyTextView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Main emergency message
            Text("지금 즉시 대피소로 이동하세요!")
                .font(.system(size: 24))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                
            
            // Location warning message
            Text("게신 곳이 화재 경로에 포함되었습니다.")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
                
            
            Image(systemName: "book.closed")
                .font(.system(size: 44))
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
            
            Text("행동가이드")
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
                
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    EvacuationLocationView()
}
