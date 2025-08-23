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
        Image(systemName: "house.fill")
            .font(.system(size: 40))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    HouseIconView()
        .background(Color.black)
}
