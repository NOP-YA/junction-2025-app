//
//  HomeView.swift
//  JunctionBase
//
//  Created by Henry on 8/20/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var pathModel: PathModel
    
    var body: some View {
        Text("노바 하이퍼 ")
            .font(.pretendardBold20)
            .foregroundStyle(.black)
    }
}

#Preview {
    HomeView()
}
