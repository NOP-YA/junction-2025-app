//
//  HomeViewModel.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import Foundation
import Combine
import CoreLocation

final class HomeViewModel: ObservableObject {
    @Published var userPrompt: String = ""
    @Published var responseText: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var riskScore: Double = 0.0
    @Published var kfsIndexNorm: Double = 60.0 // demo default; 0..100
    @Published var riskCategory: KFSCategory = .low
    @Published var riskStage: KFSAlertStage = .attention

    private let azureAIService: AzureAIService
    private let firmsService = FirmsService()

    init(azureAIService: AzureAIService = AzureAIService()) {
        self.azureAIService = azureAIService
    }

    func sendChatRequest() {
        let trimmed = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.errorMessage = "Please enter a prompt."
            return
        }

        isLoading = true
        errorMessage = nil
        responseText = ""

        azureAIService.sendChat(userPrompt: trimmed) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let text):
                    if !text.isEmpty {
                        self.responseText = text
                    } else {
                        self.errorMessage = "No response content found."
                    }
                case .failure(let error):
                    self.errorMessage = "Request failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateDerivedStates(from index: Double) {
        let cat = kfsCategory(from: index)
        self.riskCategory = cat
        switch index {
        case ...50:    self.riskStage = .attention
        case 51...65:  self.riskStage = .caution
        case 66...85:  self.riskStage = .warning
        default:       self.riskStage = .severe
        }
    }

    /// Parse FIRMS JSON and update riskScore using current kfsIndexNorm, filtering by radius around the user
    func updateRisk(from jsonData: Data, userLocation: CLLocationCoordinate2D, radiusMeters: Double) {
        do {
            let points = try firmsService.parsePoints(from: jsonData)
            // Filter points within the given radius from the user's location
            let nearby = points.filter { haversineMeters(userLocation, $0.coordinate) <= radiusMeters }
            guard !nearby.isEmpty else {
                DispatchQueue.main.async { self.riskScore = 0 }
                return
            }

            // For demo: make a single cluster centered at the user's location
            let cluster = FireCluster(id: "local", centroid: userLocation, members: nearby, suggestedRadiusM: nil)

            let firms = firmsScore(cluster: cluster)
            let inferredRadius = inferRadiusM(for: cluster)
            let distance = 0.0 // centroid == user location in this demo

            let risk = finalRisk(
                kfsIndexNorm: kfsIndexNorm,
                firmsClusterScore: firms,
                alpha: 0.6,
                distanceM: distance,
                radiusM: max(inferredRadius, radiusMeters)
            )
            DispatchQueue.main.async {
                self.riskScore = risk
                self.updateDerivedStates(from: risk)
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "FIRMS JSON parse failed: \(error.localizedDescription)" }
        }
    }

    /// Demo: Read `firms_fire_demo.json` from bundle and compute risk within 10km of Pohang-si Buk-gu
    func runDemoRiskCalculation() {
        guard let url = Bundle.main.url(forResource: "firms_fire_demo", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            self.errorMessage = "Demo JSON not found in bundle."
            return
        }
        // Pohang-si Buk-gu approx center
        let pohangBukgu = CLLocationCoordinate2D(latitude: 36.041, longitude: 129.365)
        let seoul = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let busan = CLLocationCoordinate2D(latitude: 35.1796, longitude: 129.0756)
        let daegu = CLLocationCoordinate2D(latitude: 35.8714, longitude: 128.6014)
        updateRisk(from: data, userLocation: daegu, radiusMeters: 10_000)
    }
}
