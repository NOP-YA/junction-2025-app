//
//  MapNavigationService.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import Foundation
import UIKit
import CoreLocation

/// 지도 앱 연동 서비스 - 대피소 검색
class MapNavigationService {
    
    /// 설치된 지도 앱 확인
    static func checkInstalledMapApps() {
        let apps = [
            ("카카오맵", "kakaomap://"),
            ("네이버맵", "nmap://"),
            ("애플지도", "maps://")
        ]
        
        print("🗺️ 설치된 지도 앱 확인:")
        for (name, scheme) in apps {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                print("✅ \(name) 설치됨")
            } else {
                print("❌ \(name) 미설치")
            }
        }
    }
    
    /// 사용 가능한 지도 앱들을 우선순위대로 체크해서 대피소 검색
    static func openShelterSearch(userLocation: CLLocationCoordinate2D?) {
        print("🗺️ 지도 앱 연동 시작...")
        checkInstalledMapApps()
        
        // 1순위: 카카오맵
        if tryOpenKakaoMap(userLocation: userLocation) {
            print("✅ 카카오맵 실행됨")
            return
        }
        
        // 2순위: 네이버맵
        if tryOpenNaverMap(userLocation: userLocation) {
            print("✅ 네이버맵 실행됨")
            return
        }
        
        // 3순위: 애플 지도 (더 정확한 검색어 사용)
        if tryOpenAppleMaps(userLocation: userLocation) {
            print("✅ 애플지도 실행됨")
            return
        }
        
        // 마지막: 웹 검색
        print("🌐 웹 검색으로 대체")
        openWebSearch()
    }
    
    /// 카카오맵으로 대피소 검색
    private static func tryOpenKakaoMap(userLocation: CLLocationCoordinate2D?) -> Bool {
        // 여러 검색어 시도 (재난대피시설, 대피소, 민방위대피소)
        let searchTerms = ["재난대피시설", "민방위대피소", "대피소"]
        
        for term in searchTerms {
            guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { continue }
            
            var urlString = "kakaomap://search?q=\(encodedTerm)"
            if let location = userLocation {
                urlString += "&lat=\(location.latitude)&lng=\(location.longitude)"
            }
            
            guard let url = URL(string: urlString) else { continue }
            
            if UIApplication.shared.canOpenURL(url) {
                print("🔍 카카오맵 검색어: \(term)")
                UIApplication.shared.open(url)
                return true
            }
        }
        
        print("❌ 카카오맵 설치되지 않음")
        return false
    }
    
    /// 네이버맵으로 대피소 검색
    private static func tryOpenNaverMap(userLocation: CLLocationCoordinate2D?) -> Bool {
        // 여러 검색어 시도
        let searchTerms = ["재난대피시설", "민방위대피소", "대피소"]
        
        for term in searchTerms {
            guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { continue }
            
            var urlString = "nmap://search?query=\(encodedTerm)"
            if let location = userLocation {
                urlString += "&lat=\(location.latitude)&lng=\(location.longitude)"
            }
            
            guard let url = URL(string: urlString) else { continue }
            
            if UIApplication.shared.canOpenURL(url) {
                print("🔍 네이버맵 검색어: \(term)")
                UIApplication.shared.open(url)
                return true
            }
        }
        
        print("❌ 네이버맵 설치되지 않음")
        return false
    }
    
    /// 애플 지도로 대피소 검색 (더 정확한 검색어 사용)
    private static func tryOpenAppleMaps(userLocation: CLLocationCoordinate2D?) -> Bool {
        // 애플 지도에서 더 정확한 결과를 위한 검색어들 (한국어 + 영어)
        let searchTerms = [
            "emergency shelter",
            "재난대피시설",  
            "evacuation center",
            "민방위대피소",
            "community center",
            "대피소"
        ]
        
        for term in searchTerms {
            guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { continue }
            
            var urlString = "maps://?q=\(encodedTerm)"
            if let location = userLocation {
                urlString += "&ll=\(location.latitude),\(location.longitude)"
            }
            
            guard let url = URL(string: urlString) else { continue }
            
            print("🔍 애플지도 검색어: \(term)")
            UIApplication.shared.open(url)
            return true
        }
        
        return false
    }
    
    /// 웹에서 대피소 검색 (마지막 수단)
    private static func openWebSearch() {
        let query = "대피소+위치".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "대피소"
        let urlString = "https://www.google.com/search?q=\(query)"
        
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
