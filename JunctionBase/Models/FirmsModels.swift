//
//  FirmsModels.swift
//  JunctionBase
//
//  Created by Henry on 8/23/25.
//

import Foundation
import CoreLocation

// NASA FIRMS (MODIS/VIIRS) 1건
public struct FirmsRaw: Codable {
    public let latitude: Double
    public let longitude: Double
    public let acq_date: String        // "YYYY-MM-DD"
    public let acq_time: String        // "HHmm" (UTC)
    public let bright_t31: Double?
    public let version: String?
    public let frp: Double?            // Fire Radiative Power
    public let scan: Double?
    public let instrument: String?     // VIIRS/MODIS
    public let satellite: String?      // N20/N21/Terra/Aqua...
    public let brightness: Double?     // K
    public let daynight: String?       // D/N
    public let confidence: String?     // "l"|"n"|"h"
    public let track: Double?
}

// 앱 내부 표준 포인트
public struct FirmsPoint {
    public let coordinate: CLLocationCoordinate2D
    public let acquiredAtUTC: Date
    public let brightness: Double?
    public let frp: Double?
    public let confidence: String?     // "l"|"n"|"h"
    public let sensor: String?         // VIIRS/MODIS
    public let satellite: String?
}
