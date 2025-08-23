//
//  FirmsService.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import Foundation
import CoreLocation

public enum FirmsServiceError: Error {
    case invalidData
    case decodeFailed
    case dateParseFailed
}

public final class FirmsService {
    public init() {}

    // FIRMS JSON(Data) -> FirmsPoint[]
    public func parsePoints(from jsonData: Data) throws -> [FirmsPoint] {
        let decoder = JSONDecoder()
        let raws: [FirmsRaw]
        do {
            raws = try decoder.decode([FirmsRaw].self, from: jsonData)
        } catch {
            throw FirmsServiceError.decodeFailed
        }

        var points: [FirmsPoint] = []
        points.reserveCapacity(raws.count)

        for r in raws {
            guard let ts = Self.makeUTCDate(acqDate: r.acq_date, acqTimeHHmm: r.acq_time) else {
                // 날짜가 일부 파싱 실패해도 스킵
                continue
            }
            let p = FirmsPoint(
                coordinate: .init(latitude: r.latitude, longitude: r.longitude),
                acquiredAtUTC: ts,
                brightness: r.brightness ?? r.bright_t31,
                frp: r.frp,
                confidence: r.confidence,
                sensor: r.instrument,
                satellite: r.satellite
            )
            points.append(p)
        }
        return points
    }

    // "2025-03-22" + "0355" -> Date(UTC)
    private static func makeUTCDate(acqDate: String, acqTimeHHmm: String) -> Date? {
        // HHmm을 HH:mm으로 변환
        let hh = acqTimeHHmm.prefix(2)
        let mm = acqTimeHHmm.suffix(2)
        let iso = "\(acqDate)T\(hh):\(mm):00Z"
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: iso) { return d }
        // fractionalSeconds가 없는 경우도 지원
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: iso)
    }
}
