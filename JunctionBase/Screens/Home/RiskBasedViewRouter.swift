//
//  RiskBasedViewRouter.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

struct RiskBasedViewRouter: View {
    let riskScore: Double
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some View {
        switch RiskLevel.from(riskScore: riskScore) {
        case .immediateEvacuation:
            EvacuationLocationView(homeViewModel: homeViewModel)
        case .evacuationPreparation:
            EvacuationPreparationView()
        case .situationMonitoring:
            SituationMonitoringView()
        }
    }
}

// MARK: - Alternative View Router with Explicit RiskLevel
struct RiskLevelViewRouter: View {
    let riskLevel: RiskLevel
    
    var body: some View {
        switch riskLevel {
        case .immediateEvacuation:
            EvacuationLocationView(homeViewModel: HomeViewModel())
        case .evacuationPreparation:
            EvacuationPreparationView()
        case .situationMonitoring:
            SituationMonitoringView()
        }
    }
}

// MARK: - Preview
#Preview("High Risk") {
    RiskBasedViewRouter(riskScore: 85.0)
}

#Preview("Medium Risk") {
    RiskBasedViewRouter(riskScore: 55.0)
}

#Preview("Low Risk") {
    RiskBasedViewRouter(riskScore: 25.0)
}
