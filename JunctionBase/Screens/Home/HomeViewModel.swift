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
    @Published var riskLevel: RiskLevel = .situationMonitoring
    @Published var userHeading: Double = 0.0 // 사용자가 바라보는 방향

    private let azureAIService: AzureAIService
    private let firmsService = FirmsService()
    let locationManager = LocationManager() // public으로 변경 (테스트용 접근을 위해)
    let deviceHeadingManager = DeviceHeadingManager() // CoreMotion 기반 기기 방향 매니저
    
    // 각도 정규화를 위한 이전 헤딩 값 저장
    private var previousHeading: Double = 0.0
    private var normalizedHeading: Double = 0.0

    init(azureAIService: AzureAIService = AzureAIService()) {
        self.azureAIService = azureAIService
        setupLocationTracking()
    }
    
    private func setupLocationTracking() {
        // DeviceHeadingManager의 deviceHeading 변경사항을 구독 (CoreMotion 기반)
        deviceHeadingManager.$deviceHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newHeading in
                guard let self = self else { return }
                // 각도 정규화 적용하여 부드러운 회전 보장
                self.userHeading = self.normalizeHeadingForAnimation(newHeading)
            }
            .store(in: &cancellables)
        
        // 위치 추적 시작 (권한은 ContentView에서 요청됨)
        
        // 약간의 딜레이 후 추적 시작 (권한 다이얼로그가 표시될 시간)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.locationManager.startTracking()
            // DeviceHeadingManager 시작
            self.deviceHeadingManager.startDeviceMotionUpdates()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()

    /// 애니메이션을 위한 각도 정규화 함수
    /// 0-360도 경계를 넘나들 때 부드러운 회전을 위해 연속적인 값으로 변환
    private func normalizeHeadingForAnimation(_ newHeading: Double) -> Double {
        // 첫 번째 호출인 경우
        if previousHeading == 0.0 && normalizedHeading == 0.0 {
            previousHeading = newHeading
            normalizedHeading = newHeading
            return newHeading
        }
        
        // 새로운 각도와 이전 각도의 차이 계산
        var angleDifference = newHeading - previousHeading
        
        // 각도 차이를 -180 ~ +180 범위로 정규화 (최단 경로)
        while angleDifference > 180.0 {
            angleDifference -= 360.0
        }
        while angleDifference < -180.0 {
            angleDifference += 360.0
        }
        
        // 정규화된 헤딩 업데이트 (연속적인 값)
        normalizedHeading += angleDifference
        previousHeading = newHeading
        
        return normalizedHeading
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
        self.riskLevel = RiskLevel.from(riskScore: index)
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
        updateRisk(from: data, userLocation: pohangBukgu, radiusMeters: 10_000)
    }
}
