//
//  ContentView.swift
//  JunctionBase
//
//  Created by Henry on 8/20/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showLocationPermissionAlert = false
    
    var body: some View {
        NavigationView {
            NavigationStack {
            VStack(spacing: 30) {
                // 앱 로고/제목
                VStack(spacing: 15) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                    
                    Text("JunctionBase")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("화재 위험 감지 시스템")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 메인 메뉴 버튼들
                VStack(spacing: 20) {
                    NavigationLink(destination: EvacuationLocationView(homeViewModel: homeViewModel)) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("즉시 대피")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    NavigationLink(destination: EvacuationPreparationView()) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.orange)
                            Text("대피 준비")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    NavigationLink(destination: SituationMonitoringView()) {
                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.blue)
                            Text("상황 모니터링")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 위치 권한 상태 표시
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: homeViewModel.locationManager.authorizationStatus == .authorizedWhenInUse || homeViewModel.locationManager.authorizationStatus == .authorizedAlways ? "location.fill" : "location.slash")
                            .foregroundColor(homeViewModel.locationManager.authorizationStatus == .authorizedWhenInUse || homeViewModel.locationManager.authorizationStatus == .authorizedAlways ? .green : .red)
                        Text(homeViewModel.locationManager.authorizationStatus == .authorizedWhenInUse || homeViewModel.locationManager.authorizationStatus == .authorizedAlways ? "위치 권한 허용됨" : "위치 권한 필요")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if homeViewModel.locationManager.authorizationStatus != .authorizedWhenInUse && homeViewModel.locationManager.authorizationStatus != .authorizedAlways {
                        Button("위치 권한 요청") {
                            homeViewModel.locationManager.requestLocationPermission()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            }
        }
        .onAppear {
            // 위치 권한 요청
            homeViewModel.locationManager.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}
