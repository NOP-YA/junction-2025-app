//
//  HouseIconComponent.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

// MARK: - House Icon View
struct HouseIconView: View {
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
    }
}

// MARK: - Preview
#Preview {
    HouseIconView()
        .background(Color.black)
}
