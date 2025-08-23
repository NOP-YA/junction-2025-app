//
//  RiskCalculator.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import Foundation
import CoreLocation
    
// 산림청 내부 표준화 점수 (0..100) 입력 전제
public enum KFSCategory: String {
    case low = "낮음"            // 0 ~ 50
    case somewhatHigh = "다소 높음" // 51 ~ 65
    case high = "높음"            // 66 ~ 85
    case veryHigh = "매우 높음"     // 86 ~ 100
}

public func kfsCategoryToNorm(_ c: KFSCategory) -> Double {
    switch c {
    case .low:          return 25  // midpoint of 0~50
    case .somewhatHigh: return 58  // midpoint of 51~65
    case .high:         return 76  // midpoint of 66~85
    case .veryHigh:     return 93  // midpoint of 86~100
    }
}

/// Map a 0..100 KFS index to the official category
public func kfsCategory(from index: Double) -> KFSCategory {
    let v = max(0, min(100, index))
    if v <= 50 { return .low }
    if v <= 65 { return .somewhatHigh }
    if v <= 85 { return .high }
    return .veryHigh
}

public struct FireCluster {
    public let id: String
    public let centroid: CLLocationCoordinate2D
    public let members: [FirmsPoint]
    public let suggestedRadiusM: Double? // Azure가 주면 사용
    public init(id: String, centroid: CLLocationCoordinate2D, members: [FirmsPoint], suggestedRadiusM: Double? = nil) {
        self.id = id
        self.centroid = centroid
        self.members = members
        self.suggestedRadiusM = suggestedRadiusM
    }
}

// MARK: - KFS Alert Stages & Large-fire advisories
public enum KFSAlertStage: String { // 산불재난 위기경보 단계
    case attention = "관심"
    case caution   = "주의"
    case warning   = "경계"
    case severe    = "심각"
}

/// Determine alert stage based on regional coverage percentages (0..100) of areas above KFS thresholds.
/// - Parameters:
///   - percGE51: percentage of regions with index ≥ 51
///   - percGE66: percentage of regions with index ≥ 66
///   - percGE86: percentage of regions with index ≥ 86
/// - Returns: Highest stage that meets the 70% coverage rule.
public func kfsAlertStage(percGE51: Double, percGE66: Double, percGE86: Double) -> KFSAlertStage {
    if percGE86 >= 70 { return .severe }
    if percGE66 >= 70 { return .warning }
    if percGE51 >= 70 { return .caution }
    return .attention
}

public enum LargeFireAlert: String { // 대형산불 위험 예보
    case none     = "해제"
    case advisory = "대형산불 주의보"
    case warning  = "대형산불 경보"
}

/// Determine large-fire advisory based on KFS index, effective humidity, duration, and wind speed.
/// - Parameters:
///   - index: KFS risk index (0..100)
///   - effectiveHumidity: 실효습도 (%)
///   - daysEffectiveHumidityLow: number of consecutive days meeting humidity criterion
///   - windMps: wind speed in m/s
public func largeFireAlert(index: Double,
                           effectiveHumidity: Double,
                           daysEffectiveHumidityLow: Int,
                           windMps: Double) -> LargeFireAlert {
    guard index >= 51 else { return .none }
    // 경보: 실효습도 < 30% (2일 이상) AND 풍속 ≥ 11 m/s
    if effectiveHumidity < 30, daysEffectiveHumidityLow >= 2, windMps >= 11 { return .warning }
    // 주의보: 실효습도 ≤ 45% (2일 이상) AND 풍속 ≥ 7 m/s
    if effectiveHumidity <= 45, daysEffectiveHumidityLow >= 2, windMps >= 7 { return .advisory }
    return .none
}

// MARK: - 점수 로직

private func confWeight(_ c: String?) -> Double {
    switch (c ?? "").lowercased() {
    case "h": return 20
    case "n": return 12
    case "l": return 5
    default:  return 8
    }
}

private func recencyBonus(hours: Double) -> Double {
    // 0h → +15, 24h → +0
    max(0, 15.0 * (1.0 - min(24.0, hours)/24.0))
}

public func firmsScore(cluster: FireCluster, now: Date = Date()) -> Double {
    guard !cluster.members.isEmpty else { return 0 }
    let frps = cluster.members.compactMap { $0.frp }
    let brs  = cluster.members.compactMap { $0.brightness }
    let confs = cluster.members.map { confWeight($0.confidence) }
    let hours = cluster.members.map { now.timeIntervalSince($0.acquiredAtUTC) / 3600 }

    let frpAvg = frps.isEmpty ? 0 : frps.reduce(0,+)/Double(frps.count)
    let frpMax = frps.max() ?? 0
    let frpMixed = 0.6 * frpAvg + 0.4 * frpMax
    let frpTerm = min(300.0, frpMixed) * 0.15  // 0..45

    let brAvg = brs.isEmpty ? 0 : brs.reduce(0,+)/Double(brs.count)
    let brNorm = min(1.0, max(0.0, (brAvg - 300.0) / 100.0)) // 300~400K → 0..1
    let brTerm = brNorm * 25.0                               // 0..25

    let confAvg = confs.isEmpty ? 0 : confs.reduce(0,+)/Double(confs.count) // ~5..20
    let recAvg  = hours.isEmpty ? 24 : hours.reduce(0,+)/Double(hours.count)
    let recTerm = recencyBonus(hours: recAvg)                // 0..15

    let raw = frpTerm + brTerm + confAvg + recTerm           // ~0..105
    return min(100.0, max(0.0, raw))
}

public func inferRadiusM(for cluster: FireCluster) -> Double {
    let frpMax = cluster.members.compactMap({ $0.frp }).max() ?? 0
    let confBump = cluster.members.compactMap { $0.confidence?.lowercased() }.contains("h") ? 300.0
                   : (cluster.members.compactMap { $0.confidence?.lowercased() }.contains("n") ? 150.0 : 0.0)
    let base = 500.0
    let frpAdd = min(frpMax * 5.0, 1500.0)
    return base + frpAdd + confBump // 500~2300m
}

public func haversineMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let R = 6_371_000.0
    let dLat = (b.latitude - a.latitude) * .pi / 180
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let lat1 = a.latitude * .pi / 180
    let lat2 = b.latitude * .pi / 180
    let h = sin(dLat/2)*sin(dLat/2) + cos(lat1)*cos(lat2)*sin(dLon/2)*sin(dLon/2)
    return 2 * R * asin(min(1, sqrt(h)))
}

public func finalRisk(kfsIndexNorm: Double,
                      firmsClusterScore: Double,
                      alpha: Double,
                      distanceM: Double,
                      radiusM: Double) -> Double {
    var risk = min(100, max(0, alpha*kfsIndexNorm + (1-alpha)*firmsClusterScore))
    if distanceM <= radiusM      { risk += 15 }
    else if distanceM <= 2*radiusM { risk += 8 }
    else if distanceM <= 3*radiusM { risk += 3 }
    return min(100, risk)
}
