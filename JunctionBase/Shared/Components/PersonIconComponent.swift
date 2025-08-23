//
//  PersonIconComponent.swift
//  JunctionBase
//
//  Created by AI Assistant on 8/23/25.
//

import SwiftUI

// MARK: - Person Icon View
struct PersonIconView: View {
    var body: some View {
        ZStack {
            // White circle background
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
            
            // Person icon
            Image(systemName: "person.fill")
                .font(.system(size: 65))
                .foregroundColor(.black)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    PersonIconView()
        .background(Color.black)
}
