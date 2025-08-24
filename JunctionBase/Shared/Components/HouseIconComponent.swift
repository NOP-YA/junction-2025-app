//
//  HouseIconComponent.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI
import CoreLocation

// MARK: - House Icon View
struct HouseIconView: View {
    let userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "house.fill")
                .font(.system(size: 40))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text("Shelter")
                .font(.pretendardBold20)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
        .contentShape(Rectangle()) // 탭 영역을 전체 VStack으로 확장
        .onTapGesture {
            // 지도 앱을 열어서 대피소 검색
            MapNavigationService.openShelterSearch(userLocation: userLocation)
        }
    }
}

// MARK: - Preview
#Preview {
    HouseIconView(userLocation: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780))
        .background(Color.black)
}
