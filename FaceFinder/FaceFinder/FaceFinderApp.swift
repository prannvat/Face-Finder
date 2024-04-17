//
//  FaceFinderApp.swift
//  FaceFinder
//
//  Created by Prannvat Singh on 17/04/2024.
//

import SwiftUI

@main
struct FaceFinderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}
