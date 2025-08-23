//
//  JunctionBaseApp.swift
//  JunctionBase
//
//  Created by Henry on 8/20/25.
//

import SwiftUI

@main
struct JunctionBaseApp: App {
    var body: some Scene {
        WindowGroup {
            EvacuationLocationView()
                .environmentObject(PathModel())
        }
    }
}
